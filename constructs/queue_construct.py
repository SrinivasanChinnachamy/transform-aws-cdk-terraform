from aws_cdk import (
    Duration,
    aws_sqs as sqs,
)
from constructs import Construct

class QueueConstruct(Construct):
    """Queue layer with SQS for async processing"""
    
    def __init__(self, scope: Construct, construct_id: str, **kwargs) -> None:
        super().__init__(scope, construct_id, **kwargs)

        # Dead letter queue for failed messages
        self.dlq = sqs.Queue(
            self, "DeadLetterQueue",
            retention_period=Duration.days(14)
        )

        # Main processing queue
        self.processing_queue = sqs.Queue(
            self, "ProcessingQueue",
            visibility_timeout=Duration.seconds(300),
            retention_period=Duration.days(7),
            dead_letter_queue=sqs.DeadLetterQueue(
                max_receive_count=3,
                queue=self.dlq
            )
        )
