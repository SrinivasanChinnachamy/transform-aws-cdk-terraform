# IAM Role and Policies for API Lambda Function
# Replicates grant_send_messages and grant_write_data permissions from CDK

# IAM Role for API Lambda
resource "aws_iam_role" "api_lambda_role" {
  name = "${var.project_name}-api-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name      = "ApiLambdaRole"
    Component = "API"
  }
}

# Attach AWS managed policy for basic Lambda execution (CloudWatch Logs)
resource "aws_iam_role_policy_attachment" "api_lambda_basic" {
  role       = aws_iam_role.api_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# IAM Policy for SQS SendMessage permission
resource "aws_iam_policy" "api_lambda_sqs_policy" {
  name        = "${var.project_name}-api-lambda-sqs-policy"
  description = "Allow API Lambda to send messages to SQS queue"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:SendMessage",
          "sqs:GetQueueUrl",
          "sqs:GetQueueAttributes"
        ]
        Resource = aws_sqs_queue.processing_queue.arn
      }
    ]
  })
}

# Attach SQS policy to API Lambda role
resource "aws_iam_role_policy_attachment" "api_lambda_sqs" {
  role       = aws_iam_role.api_lambda_role.name
  policy_arn = aws_iam_policy.api_lambda_sqs_policy.arn
}

# IAM Policy for DynamoDB PutItem permission
resource "aws_iam_policy" "api_lambda_dynamodb_policy" {
  name        = "${var.project_name}-api-lambda-dynamodb-policy"
  description = "Allow API Lambda to write to DynamoDB table"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:DescribeTable"
        ]
        Resource = aws_dynamodb_table.metadata_table.arn
      }
    ]
  })
}

# Attach DynamoDB policy to API Lambda role
resource "aws_iam_role_policy_attachment" "api_lambda_dynamodb" {
  role       = aws_iam_role.api_lambda_role.name
  policy_arn = aws_iam_policy.api_lambda_dynamodb_policy.arn
}
