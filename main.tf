provider "aws" {
  region = "us-east-1" # Main region
}

provider "aws" {
  alias  = "replica" # Replica region alias
  region = "us-west-2" # Replica region
}

# Main DynamoDB table with stream enabled in the primary region (us-east-1)
resource "aws_dynamodb_table" "main_table" {
  name             = "Dynamodb_table_example"
  billing_mode     = "PROVISIONED"
  read_capacity    = 5
  write_capacity   = 5
  hash_key         = "id"

  attribute {
    name = "id"
    type = "S"
  }

  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"
}

# Autoscaling for the main DynamoDB table's read capacity in the primary region (us-east-1)
resource "aws_appautoscaling_target" "main_table_read_target" {
  max_capacity       = 20
  min_capacity       = 5
  resource_id        = "table/${aws_dynamodb_table.main_table.name}"
  scalable_dimension = "dynamodb:table:ReadCapacityUnits"
  service_namespace  = "dynamodb"
}

resource "aws_appautoscaling_policy" "main_table_read_policy" {
  name               = "Dynamodb_table_exampleReadCapacityPolicy"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.main_table_read_target.resource_id
  scalable_dimension = aws_appautoscaling_target.main_table_read_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.main_table_read_target.service_namespace
  
  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "DynamoDBReadCapacityUtilization"
    }
    target_value = 70.0
  }
}

# Autoscaling for the main DynamoDB table's write capacity in the primary region (us-east-1)
resource "aws_appautoscaling_target" "main_table_write_target" {
  max_capacity       = 20
  min_capacity       = 5
  resource_id        = "table/${aws_dynamodb_table.main_table.name}"
  scalable_dimension = "dynamodb:table:WriteCapacityUnits"
  service_namespace  = "dynamodb"
}

resource "aws_appautoscaling_policy" "main_table_write_policy" {
  name               = "Dynamodb_table_exampleWriteCapacityPolicy"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.main_table_write_target.resource_id
  scalable_dimension = aws_appautoscaling_target.main_table_write_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.main_table_write_target.service_namespace
  
  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "DynamoDBWriteCapacityUtilization"
    }
    target_value = 70.0
  }
}

# Replica DynamoDB table with stream enabled in the secondary region (us-west-2)
resource "aws_dynamodb_table" "replica_table" {
  provider          = aws.replica
  name              = "Dynamodb_table_example"
  billing_mode      = "PROVISIONED"
  read_capacity     = 5
  write_capacity    = 5
  hash_key          = "id"

  attribute {
    name = "id"
    type = "S"
  }

  stream_enabled    = true
  stream_view_type  = "NEW_AND_OLD_IMAGES"
}

# Autoscaling for the replica DynamoDB table's read capacity in the secondary region (us-west-2)
resource "aws_appautoscaling_target" "replica_table_read_target" {
  provider          = aws.replica
  max_capacity      = 20
  min_capacity      = 5
  resource_id       = "table/${aws_dynamodb_table.replica_table.name}"
  scalable_dimension = "dynamodb:table:ReadCapacityUnits"
  service_namespace = "dynamodb"
}

resource "aws_appautoscaling_policy" "replica_table_read_policy" {
  provider          = aws.replica
  name              = "TrafficReportingMetadataProdReadCapacityPolicyReplica"
  policy_type       = "TargetTrackingScaling"
  resource_id       = aws_appautoscaling_target.replica_table_read_target.resource_id
  scalable_dimension = aws_appautoscaling_target.replica_table_read_target.scalable_dimension
  service_namespace = aws_appautoscaling_target.replica_table_read_target.service_namespace
  
  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "DynamoDBReadCapacityUtilization"
    }
    target_value = 70.0
  }
}

# Autoscaling for the replica DynamoDB table's write capacity in the secondary region (us-west-2)
resource "aws_appautoscaling_target" "replica_table_write_target" {
  provider          = aws.replica
  max_capacity      = 20
  min_capacity      = 5
  resource_id       = "table/${aws_dynamodb_table.replica_table.name}"
  scalable_dimension = "dynamodb:table:WriteCapacityUnits"
  service_namespace = "dynamodb"
}

resource "aws_appautoscaling_policy" "replica_table_write_policy" {
  provider          = aws.replica
  name              = "TrafficReportingMetadataProdWriteCapacityPolicyReplica"
  policy_type       = "TargetTrackingScaling"
  resource_id       = aws_appautoscaling_target.replica_table_write_target.resource_id
  scalable_dimension = aws_appautoscaling_target.replica_table_write_target.scalable_dimension
  service_namespace = aws_appautoscaling_target.replica_table_write_target.service_namespace
  
  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "DynamoDBWriteCapacityUtilization"
    }
    target_value = 70.0
  }
}

# Global Table setup which includes the primary and replica tables
resource "aws_dynamodb_global_table" "global_table" {
  name = "Dynamodb_table_example"
  replica {
    region_name = "us-east-1"
  }
  replica {
    region_name = "us-west-2"
  }

  depends_on = [
    aws_appautoscaling_policy.main_table_write_policy,
    aws_appautoscaling_policy.replica_table_write_policy,
  ]
}

# Kinesis Data Stream in the primary region (us-east-1)
resource "aws_kinesis_stream" "kinesis_stream" {
  name             = "example-kinesis-stream"
  shard_count      = 1
  retention_period = 24

  tags = {
    Name = "Example Kinesis Stream"
  }
}

# DynamoDB table that will act as a destination for the Kinesis Data Stream
resource "aws_dynamodb_table" "kinesis_destination_table" {
  name           = "Kinesis_Destination_Table"
  billing_mode   = "PROVISIONED"
  read_capacity  = 5
  write_capacity = 5
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }

  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  tags = {
    Name = "Destination Table for Kinesis Stream"
  }
}

# Configuration to set up the stream as a destination for DynamoDB table
resource "aws_dynamodb_kinesis_streaming_destination" "kinesis_destination" {
  table_name = aws_dynamodb_table.kinesis_destination_table.name
  stream_arn = aws_kinesis_stream.kinesis_stream.arn
}
