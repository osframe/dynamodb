# dynamodb
Multi-region AWS infrastructure setup using Terraform for scalable DynamoDB tables with enabled streams, autoscaling policies, and Kinesis Data Stream integration for robust data handling and application deployment.

# AWS DynamoDB and Kinesis Infrastructure

This Terraform configuration sets up a multi-region DynamoDB infrastructure with autoscaling policies and a Kinesis Data Stream in the primary region.

## Providers

- Two AWS providers are configured: one for the **primary region (us-east-1)** and another for the **replica region (us-west-2)**.

## Resources

- A `aws_dynamodb_table` resource named `main_table` with streaming enabled is created in the primary region.
- Autoscaling targets and policies for both read and write capacities are set for the `main_table`.
- A replica `aws_dynamodb_table` named `replica_table` with streaming enabled is created in the secondary region.
- Autoscaling targets and policies are similarly set for the `replica_table`.
- A `aws_dynamodb_global_table` named `global_table` is set up, which combines the primary and replica DynamoDB tables for global access.
- A `aws_kinesis_stream` resource named `kinesis_stream` is configured in the primary region with a retention period of 24 hours.
- Another `aws_dynamodb_table` named `kinesis_destination_table` will act as the destination table for the Kinesis Data Stream.
- `aws_dynamodb_kinesis_streaming_destination` attaches the Kinesis Data Stream to the destination DynamoDB table.

## Usage

To deploy this infrastructure, follow these steps:

1. Ensure you have the required AWS credentials and permissions set up in your environment.
2. Initialize Terraform with `terraform init`.
3. Review the changes Terraform will make with `terraform plan`.
4. Apply the configuration with `terraform apply`.

## Variables

- `deploy_scripts_ver`: Used to specify the version of the deployment scripts to be deployed from Artifactory.
- `kerberos_keytab`: Should hold the path to a valid Kerberos keytab file for authentication purposes.
- `asl_ver`: The version of the 'ap-stream-lake' application that the script will use or deploy.

Ensure that these variables are set correctly before running Terraform commands.

## Important Notes

- The DynamoDB tables are set up with a `PROVISIONED` billing mode and a default read/write capacity set to 5. These values can be adjusted as needed.
- Autoscaling policies aim for a 70% utilization target for both read and write capacities.
- The Kinesis Data Stream is configured with a shard count of 1; adjust the shard count based on your expected workload.

For more information on Terraform's AWS provider and configuration options, please visit the [Terraform AWS Provider documentation](https://www.terraform.io/docs/providers/aws/index.html).
