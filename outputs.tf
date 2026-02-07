# Terraform Outputs
# Matches CDK CfnOutput values from event_driven_stack.py

# API Gateway endpoint URL
output "api_url" {
  description = "API Gateway endpoint URL"
  value       = aws_api_gateway_stage.prod.invoke_url
}

# S3 Bucket Name
output "bucket_name" {
  description = "S3 bucket for results"
  value       = aws_s3_bucket.data_bucket.id
}

# SNS Topic ARN
output "topic_arn" {
  description = "SNS topic for failure notifications (SRE team)"
  value       = aws_sns_topic.notification_topic.arn
}
