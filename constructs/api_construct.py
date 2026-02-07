from aws_cdk import (
    aws_lambda as _lambda,
    aws_apigateway as apigw,
)
from constructs import Construct

class ApiConstruct(Construct):
    """API layer with API Gateway and Lambda handler"""
    
    def __init__(
        self, 
        scope: Construct, 
        construct_id: str,
        queue_url: str,
        table_name: str,
        **kwargs
    ) -> None:
        super().__init__(scope, construct_id, **kwargs)

        # API Lambda function
        self.api_function = _lambda.Function(
            self, "ApiFunction",
            runtime=_lambda.Runtime.PYTHON_3_12,
            handler="index.handler",
            code=_lambda.Code.from_inline("""
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
"""),
            environment={
                'QUEUE_URL': queue_url,
                'TABLE_NAME': table_name
            }
        )

        # API Gateway
        self.api = apigw.RestApi(
            self, "DataApi",
            rest_api_name="Data Processing API",
            description="API for submitting data processing requests"
        )

        self.api.root.add_method("POST", apigw.LambdaIntegration(self.api_function))
