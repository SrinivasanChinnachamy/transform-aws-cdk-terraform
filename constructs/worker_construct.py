from aws_cdk import (
    Duration,
    aws_lambda as _lambda,
    aws_lambda_event_sources as lambda_event_sources,
    aws_sqs as sqs,
)
from constructs import Construct

class WorkerConstruct(Construct):
    """Worker layer with Lambda for async processing"""
    
    def __init__(
        self, 
        scope: Construct, 
        construct_id: str,
        processing_queue: sqs.Queue,
        dlq: sqs.Queue,
        bucket_name: str,
        table_name: str,
        topic_arn: str,
        **kwargs
    ) -> None:
        super().__init__(scope, construct_id, **kwargs)

        # Worker Lambda function
        self.worker_function = _lambda.Function(
            self, "WorkerFunction",
            runtime=_lambda.Runtime.PYTHON_3_12,
            handler="index.handler",
            timeout=Duration.seconds(300),
            code=_lambda.Code.from_inline("""
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
                Message=f"Request ID: {message.get('requestId', 'unknown')}\nError: {str(e)}\nMessage: {json.dumps(message)}"
            )
            raise
    
    return {'statusCode': 200}
"""),
            environment={
                'BUCKET_NAME': bucket_name,
                'TABLE_NAME': table_name,
                'TOPIC_ARN': topic_arn
            },
            dead_letter_queue=dlq
        )

        # Add SQS event source
        self.worker_function.add_event_source(
            lambda_event_sources.SqsEventSource(
                processing_queue,
                batch_size=10
            )
        )
