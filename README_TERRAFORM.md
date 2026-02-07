# Terraform Configuration for Event-Driven Data Processing Stack

This directory contains Terraform configuration files that replicate the AWS CDK Python infrastructure defined in the `event_driven_stack.py` and associated construct files.

## Overview

This Terraform module provisions an event-driven data processing architecture on AWS with the following components:

- **API Layer**: API Gateway REST API with Lambda function for accepting processing requests
- **Queue Layer**: SQS queues for async processing with Dead Letter Queue (DLQ) for failed messages
- **Storage Layer**: S3 bucket for results and DynamoDB table for metadata tracking
- **Worker Layer**: Lambda function for processing messages from the queue
- **Notification Layer**: SNS topic for failure notifications to SRE team

## Architecture

```
Client Request → API Gateway → API Lambda → SQS Queue
                                              ↓
                                         Worker Lambda → S3 Bucket (results)
                                              ↓            DynamoDB Table (metadata)
                                         SNS Topic (failures)
                                              ↓
                                         Dead Letter Queue (DLQ)
```

## File Structure

```
.
├── versions.tf              # Terraform and provider version constraints
├── main.tf                  # AWS provider configuration
├── variables.tf             # Input variable definitions
├── terraform.tfvars         # Variable values (customize as needed)
├── outputs.tf               # Output definitions
├── storage.tf               # S3 bucket and DynamoDB table
├── queue.tf                 # SQS queues (processing queue and DLQ)
├── notification.tf          # SNS topic for notifications
├── api_lambda.tf            # API Lambda function
├── iam_api_lambda.tf        # IAM role and policies for API Lambda
├── api_gateway.tf           # API Gateway REST API
├── worker_lambda.tf         # Worker Lambda function with SQS event source
├── iam_worker_lambda.tf     # IAM role and policies for Worker Lambda
└── README_TERRAFORM.md      # This file
```

## Prerequisites

- Terraform >= 1.0
- AWS credentials configured (via `aws configure` or environment variables)
- Appropriate AWS IAM permissions to create resources

## Quick Start

1. **Initialize Terraform**:
   ```bash
   terraform init
   ```

2. **Review the planned changes**:
   ```bash
   terraform plan
   ```

3. **Apply the configuration**:
   ```bash
   terraform apply
   ```

4. **View outputs**:
   ```bash
   terraform output
   ```

5. **Destroy resources when done**:
   ```bash
   terraform destroy
   ```

## Configuration

### Required Variables

All variables have default values. You can customize them in `terraform.tfvars`:

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `aws_region` | AWS region for resource deployment | `us-east-1` | No |
| `aws_account_id` | AWS Account ID | `""` | No |
| `environment` | Environment name (dev, staging, production) | `dev` | No |
| `project_name` | Project name for resource naming | `event-driven-stack` | No |

### Customizing Variables

Copy the example file and modify as needed:

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
```

## Outputs

After applying, the following outputs are available:

| Output | Description |
|--------|-------------|
| `api_url` | API Gateway endpoint URL for submitting requests |
| `bucket_name` | S3 bucket name for processing results |
| `topic_arn` | SNS topic ARN for failure notifications |

## CDK to Terraform Migration Guide

### Resource Mapping

| CDK Construct | Terraform Resource | Notes |
|---------------|-------------------|-------|
| `s3.Bucket` | `aws_s3_bucket` | Added versioning, lifecycle, and public access block |
| `dynamodb.Table` | `aws_dynamodb_table` | On-demand billing mode preserved |
| `sqs.Queue` | `aws_sqs_queue` | DLQ configuration via redrive_policy |
| `sns.Topic` | `aws_sns_topic` | Display name preserved |
| `_lambda.Function` | `aws_lambda_function` | Code packaged with archive_file data source |
| `apigw.RestApi` | `aws_api_gateway_rest_api` | Explicit deployment and stage resources |
| `lambda_event_sources.SqsEventSource` | `aws_lambda_event_source_mapping` | Batch size preserved |

### Property Mappings

| CDK Property | Terraform Attribute | Transformation |
|--------------|---------------------|----------------|
| `RemovalPolicy.DESTROY` | `force_destroy = true` | S3 buckets |
| `RemovalPolicy.DESTROY` | `deletion_protection_enabled = false` | DynamoDB tables |
| `Duration.days(14)` | `message_retention_seconds = 1209600` | SQS retention |
| `Duration.seconds(300)` | `visibility_timeout_seconds = 300` | SQS visibility |
| `Runtime.PYTHON_3_12` | `runtime = "python3.12"` | Lambda runtime |
| `Code.from_inline()` | `data.archive_file` | Lambda code packaging |
| `grant_send_messages()` | IAM policy with `sqs:SendMessage` | Explicit IAM policy |
| `grant_write_data()` | IAM policy with `dynamodb:PutItem` | Explicit IAM policy |
| `grant_write()` | IAM policy with `s3:PutObject` | Explicit IAM policy |
| `grant_publish()` | IAM policy with `sns:Publish` | Explicit IAM policy |

### Deployment Process Differences

| CDK | Terraform | Notes |
|-----|-----------|-------|
| `cdk deploy` | `terraform apply` | Terraform requires explicit confirmation |
| `cdk destroy` | `terraform destroy` | Terraform destroys all resources in state |
| `cdk diff` | `terraform plan` | Shows proposed changes |
| `cdk synth` | N/A | Terraform works directly with HCL |
| CloudFormation state | `terraform.tfstate` | State stored locally or remotely |

## State Management

### Local State (Current Configuration)

The current configuration uses local state storage (`terraform.tfstate` file). This is suitable for development but **not recommended for production**.

### Remote State (Recommended for Production)

For production environments, configure remote state storage in S3 with DynamoDB for state locking:

1. Create an S3 bucket for state storage:
   ```bash
   aws s3 mb s3://your-terraform-state-bucket
   ```

2. Create a DynamoDB table for state locking:
   ```bash
   aws dynamodb create-table \
     --table-name terraform-state-lock \
     --attribute-definitions AttributeName=LockID,AttributeType=S \
     --key-schema AttributeName=LockID,KeyType=HASH \
     --billing-mode PAY_PER_REQUEST
   ```

3. Update `versions.tf` backend configuration:
   ```hcl
   terraform {
     backend "s3" {
       bucket         = "your-terraform-state-bucket"
       key            = "event-driven-stack/terraform.tfstate"
       region         = "us-east-1"
       dynamodb_table = "terraform-state-lock"
       encrypt        = true
     }
   }
   ```

4. Re-initialize Terraform:
   ```bash
   terraform init -migrate-state
   ```

## Importing Existing CDK Resources

If you have existing resources deployed via CDK and want to manage them with Terraform:

1. **Identify resource IDs** from AWS Console or CLI
2. **Import each resource**:
   ```bash
   # Example: Import S3 bucket
   terraform import aws_s3_bucket.data_bucket your-bucket-name
   
   # Example: Import DynamoDB table
   terraform import aws_dynamodb_table.metadata_table your-table-name
   
   # Example: Import Lambda function
   terraform import aws_lambda_function.api_function your-function-name
   ```

3. **Verify state**:
   ```bash
   terraform plan
   ```

**Warning**: Importing is complex and error-prone. Consider deploying to a new environment instead.

## Resource Naming

Resources are named using the `project_name` variable:

- S3 Bucket: `${project_name}-data-XXXXX` (random suffix)
- DynamoDB Table: `${project_name}-metadata-table`
- SQS Queues: `${project_name}-processing-queue`, `${project_name}-dlq`
- SNS Topic: `${project_name}-failure-notifications`
- Lambda Functions: `${project_name}-api-function`, `${project_name}-worker-function`
- IAM Roles: `${project_name}-api-lambda-role`, `${project_name}-worker-lambda-role`

## IAM Permissions

The Lambda functions require the following IAM permissions (automatically configured):

### API Lambda
- CloudWatch Logs: Write logs
- SQS: SendMessage to processing queue
- DynamoDB: PutItem to metadata table

### Worker Lambda
- CloudWatch Logs: Write logs
- S3: PutObject to data bucket
- DynamoDB: UpdateItem in metadata table
- SNS: Publish to notification topic
- SQS: ReceiveMessage, DeleteMessage from processing queue
- SQS: SendMessage to DLQ (for dead letter config)

## Monitoring and Debugging

- **CloudWatch Logs**: Lambda execution logs available in CloudWatch Logs
- **API Gateway Logs**: Configure stage-level logging in `api_gateway.tf`
- **SQS Metrics**: Monitor queue depth, message age, and DLQ activity
- **DynamoDB Metrics**: Monitor read/write capacity (not applicable with on-demand)
- **Lambda Metrics**: Monitor invocations, errors, and duration

## Security Best Practices

- ✅ S3 bucket has public access blocked
- ✅ IAM policies follow least privilege principle
- ✅ No hardcoded credentials (use AWS credentials chain)
- ✅ Lambda functions use environment variables for configuration
- ✅ API Gateway has no authentication (consider adding API keys or IAM auth)
- ⚠️ Consider enabling AWS WAF for API Gateway
- ⚠️ Consider encrypting S3 bucket with KMS
- ⚠️ Consider encrypting DynamoDB table with KMS
- ⚠️ Consider encrypting SQS queues with KMS

## Cost Considerations

- **Lambda**: Pay per invocation and execution time (free tier: 1M requests/month)
- **API Gateway**: Pay per request (free tier: 1M requests/month)
- **S3**: Pay per storage and requests (free tier: 5GB/month)
- **DynamoDB**: On-demand billing (pay per request)
- **SQS**: Pay per request (free tier: 1M requests/month)
- **SNS**: Pay per notification (free tier: 1,000 notifications/month)
- **CloudWatch Logs**: Pay per GB ingested and stored

## Troubleshooting

### Common Issues

1. **Terraform init fails**:
   - Ensure AWS credentials are configured
   - Check network connectivity to AWS

2. **Validation errors**:
   - Run `terraform validate` to identify syntax errors
   - Check resource attribute references

3. **Apply fails with permission errors**:
   - Ensure IAM user/role has necessary permissions
   - Check AWS service quotas

4. **Lambda function errors**:
   - Check CloudWatch Logs for execution errors
   - Verify environment variables are set correctly

5. **API Gateway returns errors**:
   - Verify Lambda permission allows API Gateway invocation
   - Check API Gateway integration configuration

## Maintenance

### Updating Resources

1. Modify Terraform configuration files
2. Run `terraform plan` to review changes
3. Run `terraform apply` to apply changes

### Terraform State

- **Never** edit `terraform.tfstate` manually
- Use `terraform state` commands for state manipulation
- Always backup state before major changes
- Use remote state for team collaboration

## Additional Resources

- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS CDK to Terraform Migration Guide](https://developer.hashicorp.com/terraform/cdktf)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)

## Support

For issues or questions:
1. Check Terraform documentation
2. Review AWS service documentation
3. Check CloudWatch Logs for runtime errors
4. Review Terraform state for resource configuration

## License

This configuration is provided as-is for migrating from AWS CDK to Terraform.
