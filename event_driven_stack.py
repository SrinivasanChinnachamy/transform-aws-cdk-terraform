from aws_cdk import (
    Stack,
    CfnOutput,
)
from constructs import Construct
from constructs.storage_construct import StorageConstruct
from constructs.queue_construct import QueueConstruct
from constructs.notification_construct import NotificationConstruct
from constructs.api_construct import ApiConstruct
from constructs.worker_construct import WorkerConstruct

class EventDrivenStack(Stack):
    def __init__(self, scope: Construct, construct_id: str, **kwargs) -> None:
        super().__init__(scope, construct_id, **kwargs)

        # Storage layer - S3 and DynamoDB
        storage = StorageConstruct(self, "Storage")

        # Queue layer - SQS queues
        queue = QueueConstruct(self, "Queue")

        # Notification layer - SNS topic
        notification = NotificationConstruct(self, "Notification")

        # API layer - API Gateway and Lambda
        api = ApiConstruct(
            self, "Api",
            queue_url=queue.processing_queue.queue_url,
            table_name=storage.metadata_table.table_name
        )

        # Worker layer - Processing Lambda
        worker = WorkerConstruct(
            self, "Worker",
            processing_queue=queue.processing_queue,
            dlq=queue.dlq,
            bucket_name=storage.data_bucket.bucket_name,
            table_name=storage.metadata_table.table_name,
            topic_arn=notification.notification_topic.topic_arn
        )

        # Grant permissions
        queue.processing_queue.grant_send_messages(api.api_function)
        storage.metadata_table.grant_write_data(api.api_function)
        storage.data_bucket.grant_write(worker.worker_function)
        storage.metadata_table.grant_write_data(worker.worker_function)
        notification.notification_topic.grant_publish(worker.worker_function)

        # Outputs
        CfnOutput(
            self, "ApiUrl",
            value=api.api.url,
            description="API Gateway endpoint URL"
        )

        CfnOutput(
            self, "BucketName",
            value=storage.data_bucket.bucket_name,
            description="S3 bucket for results"
        )

        CfnOutput(
            self, "TopicArn",
            value=notification.notification_topic.topic_arn,
            description="SNS topic for failure notifications (SRE team)"
        )

