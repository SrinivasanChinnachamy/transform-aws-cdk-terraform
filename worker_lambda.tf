# Worker Layer - Processing Lambda Function with SQS Event Source
# Converted from constructs/worker_construct.py

# Worker Lambda Function
resource "aws_lambda_function" "worker_function" {
  function_name = "${var.project_name}-worker-function"
  role          = aws_iam_role.worker_lambda_role.arn
  runtime       = "python3.12"
  handler       = "index.handler"
  timeout       = 300 # Duration.seconds(300)

  filename         = "lambda_worker.zip"
  source_code_hash = data.archive_file.worker_lambda_zip.output_base64sha256

  environment {
    variables = {
      BUCKET_NAME = aws_s3_bucket.data_bucket.id
      TABLE_NAME  = aws_dynamodb_table.metadata_table.name
      TOPIC_ARN   = aws_sns_topic.notification_topic.arn
    }
  }

  # Dead Letter Queue configuration
  dead_letter_config {
    target_arn = aws_sqs_queue.dlq.arn
  }

  tags = {
    Name        = "WorkerFunction"
    Component   = "Worker"
    Description = "Worker Lambda function for async data processing"
  }
}

# Archive the Worker Lambda function code
data "archive_file" "worker_lambda_zip" {
  type        = "zip"
  output_path = "${path.module}/lambda_worker.zip"

  source {
    content  = <<EOF
import json
import boto3
import os
import time

s3 = boto3.client('s3')
dynamodb = boto3.client('dynamodb')
sns = boto3.client('sns')

def handler(event, context):
    for record in event['Records']:
        try:
            message = json.loads(record['body'])
            request_id = message['requestId']
            data = message['data']
            
            # Simulate processing
            time.sleep(2)
            result = f"Processed: {json.dumps(data)}"
            
            # Store result in S3
            s3.put_object(
                Bucket=os.environ['BUCKET_NAME'],
                Key=f"results/{request_id}.json",
                Body=json.dumps({'result': result, 'requestId': request_id})
            )
            
            # Update status in DynamoDB
            dynamodb.update_item(
                TableName=os.environ['TABLE_NAME'],
                Key={'requestId': {'S': request_id}},
                UpdateExpression='SET #status = :status, #result = :result',
                ExpressionAttributeNames={'#status': 'status', '#result': 'result'},
                ExpressionAttributeValues={
                    ':status': {'S': 'completed'},
                    ':result': {'S': f"s3://{os.environ['BUCKET_NAME']}/results/{request_id}.json"}
                }
            )
            
        except Exception as e:
            error_msg = f"Error processing request {message.get('requestId', 'unknown')}: {str(e)}"
            print(error_msg)
            
            # Notify SRE team about failure
            sns.publish(
                TopicArn=os.environ['TOPIC_ARN'],
                Subject='Lambda Processing Failure - Action Required',
                Message=f"Request ID: {message.get('requestId', 'unknown')}\\nError: {str(e)}\\nMessage: {json.dumps(message)}"
            )
            raise
    
    return {'statusCode': 200}
EOF
    filename = "index.py"
  }
}

# SQS Event Source Mapping for Worker Lambda
resource "aws_lambda_event_source_mapping" "worker_sqs_trigger" {
  event_source_arn = aws_sqs_queue.processing_queue.arn
  function_name    = aws_lambda_function.worker_function.arn
  batch_size       = 10
  enabled          = true
}
