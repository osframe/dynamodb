output "dynamodb_table_name" {
  description = "Name of the main DynamoDB table."
  value       = module.dynamodb.main_table_name
}

output "kinesis_stream_name" {
  description = "Name of the Kinesis data stream."
  value       = module.kinesis.stream_name
}
