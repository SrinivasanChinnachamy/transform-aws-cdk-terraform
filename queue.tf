# Queue Layer - SQS Queues with Dead Letter Queue
# Converted from constructs/queue_construct.py

# Dead Letter Queue for failed messages
resource "aws_sqs_queue" "dlq" {
  name                      = "${var.project_name}-dlq"
  message_retention_seconds = 1209600 # 14 days (Duration.days(14))

  tags = {
    Name        = "DeadLetterQueue"
    Component   = "Queue"
    Description = "Dead letter queue for failed messages"
  }
}

# Main Processing Queue
resource "aws_sqs_queue" "processing_queue" {
  name                       = "${var.project_name}-processing-queue"
  visibility_timeout_seconds = 300    # Duration.seconds(300)
  message_retention_seconds  = 604800 # 7 days (Duration.days(7))

  # Dead Letter Queue configuration
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = 3
  })

  tags = {
    Name        = "ProcessingQueue"
    Component   = "Queue"
    Description = "Main processing queue for async processing"
  }
}
