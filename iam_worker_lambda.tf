# IAM Role and Policies for Worker Lambda Function
# Replicates grant_write, grant_write_data, grant_publish permissions from CDK

# IAM Role for Worker Lambda
resource "aws_iam_role" "worker_lambda_role" {
  name = "${var.project_name}-worker-lambda-role"

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
    Name      = "WorkerLambdaRole"
    Component = "Worker"
  }
}

# Attach AWS managed policy for basic Lambda execution (CloudWatch Logs)
resource "aws_iam_role_policy_attachment" "worker_lambda_basic" {
  role       = aws_iam_role.worker_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# IAM Policy for S3 PutObject permission
resource "aws_iam_policy" "worker_lambda_s3_policy" {
  name        = "${var.project_name}-worker-lambda-s3-policy"
  description = "Allow Worker Lambda to write objects to S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:GetObject",
          "s3:GetObjectVersion"
        ]
        Resource = "${aws_s3_bucket.data_bucket.arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Resource = aws_s3_bucket.data_bucket.arn
      }
    ]
  })
}

# Attach S3 policy to Worker Lambda role
resource "aws_iam_role_policy_attachment" "worker_lambda_s3" {
  role       = aws_iam_role.worker_lambda_role.name
  policy_arn = aws_iam_policy.worker_lambda_s3_policy.arn
}

# IAM Policy for DynamoDB UpdateItem permission
resource "aws_iam_policy" "worker_lambda_dynamodb_policy" {
  name        = "${var.project_name}-worker-lambda-dynamodb-policy"
  description = "Allow Worker Lambda to update DynamoDB table"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:UpdateItem",
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:DescribeTable"
        ]
        Resource = aws_dynamodb_table.metadata_table.arn
      }
    ]
  })
}

# Attach DynamoDB policy to Worker Lambda role
resource "aws_iam_role_policy_attachment" "worker_lambda_dynamodb" {
  role       = aws_iam_role.worker_lambda_role.name
  policy_arn = aws_iam_policy.worker_lambda_dynamodb_policy.arn
}

# IAM Policy for SNS Publish permission
resource "aws_iam_policy" "worker_lambda_sns_policy" {
  name        = "${var.project_name}-worker-lambda-sns-policy"
  description = "Allow Worker Lambda to publish to SNS topic"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = aws_sns_topic.notification_topic.arn
      }
    ]
  })
}

# Attach SNS policy to Worker Lambda role
resource "aws_iam_role_policy_attachment" "worker_lambda_sns" {
  role       = aws_iam_role.worker_lambda_role.name
  policy_arn = aws_iam_policy.worker_lambda_sns_policy.arn
}

# IAM Policy for SQS ReceiveMessage and DeleteMessage permissions
resource "aws_iam_policy" "worker_lambda_sqs_policy" {
  name        = "${var.project_name}-worker-lambda-sqs-policy"
  description = "Allow Worker Lambda to receive and delete messages from SQS queue"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:ChangeMessageVisibility"
        ]
        Resource = aws_sqs_queue.processing_queue.arn
      }
    ]
  })
}

# Attach SQS policy to Worker Lambda role
resource "aws_iam_role_policy_attachment" "worker_lambda_sqs" {
  role       = aws_iam_role.worker_lambda_role.name
  policy_arn = aws_iam_policy.worker_lambda_sqs_policy.arn
}

# IAM Policy for DLQ SendMessage permission (for dead_letter_config)
resource "aws_iam_policy" "worker_lambda_dlq_policy" {
  name        = "${var.project_name}-worker-lambda-dlq-policy"
  description = "Allow Worker Lambda to send messages to DLQ"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:SendMessage"
        ]
        Resource = aws_sqs_queue.dlq.arn
      }
    ]
  })
}

# Attach DLQ policy to Worker Lambda role
resource "aws_iam_role_policy_attachment" "worker_lambda_dlq" {
  role       = aws_iam_role.worker_lambda_role.name
  policy_arn = aws_iam_policy.worker_lambda_dlq_policy.arn
}
