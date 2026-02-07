from aws_cdk import (
    aws_sns as sns,
)
from constructs import Construct

class NotificationConstruct(Construct):
    """Notification layer with SNS for failure alerts"""
    
    def __init__(self, scope: Construct, construct_id: str, **kwargs) -> None:
        super().__init__(scope, construct_id, **kwargs)

        # SNS topic for failure notifications to SRE team
        self.notification_topic = sns.Topic(
            self, "FailureNotificationTopic",
            display_name="Lambda Failure Notifications"
        )
