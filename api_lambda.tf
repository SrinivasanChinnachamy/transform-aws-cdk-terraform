# API Layer - Lambda Function
# Converted from constructs/api_construct.py

# API Lambda Function
resource "aws_lambda_function" "api_function" {
  function_name = "${var.project_name}-api-function"
  role          = aws_iam_role.api_lambda_role.arn
  runtime       = "python3.12"
  handler       = "index.handler"
  timeout       = 60

  filename         = "lambda_api.zip"
  source_code_hash = data.archive_file.api_lambda_zip.output_base64sha256

  environment {
    variables = {
      QUEUE_URL  = aws_sqs_queue.processing_queue.url
      TABLE_NAME = aws_dynamodb_table.metadata_table.name
    }
  }

  tags = {
    Name        = "ApiFunction"
    Component   = "API"
    Description = "API Lambda function for accepting data processing requests"
  }
}

# Archive the Lambda function code
data "archive_file" "api_lambda_zip" {
  type        = "zip"
  output_path = "${path.module}/lambda_api.zip"

  source {
    content  = <<EOF
import json
import boto3
import uuid
import os
from datetime import datetime

sqs = boto3.client('sqs')
dynamodb = boto3.client('dynamodb')

def handler(event, context):
    try:
        body = json.loads(event.get('body', '{}'))
        request_id = str(uuid.uuid4())
        
        # Store metadata in DynamoDB
        dynamodb.put_item(
            TableName=os.environ['TABLE_NAME'],
            Item={
                'requestId': {'S': request_id},
                'status': {'S': 'pending'},
                'data': {'S': json.dumps(body)},
                'timestamp': {'S': datetime.now().isoformat()}
            }
        )
        
        # Send to SQS for async processing
        sqs.send_message(
            QueueUrl=os.environ['QUEUE_URL'],
            MessageBody=json.dumps({
                'requestId': request_id,
                'data': body
            })
        )
        
        return {
            'statusCode': 202,
            'body': json.dumps({'requestId': request_id, 'status': 'accepted'})
        }
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }
EOF
    filename = "index.py"
  }
}
