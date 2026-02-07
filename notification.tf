# Notification Layer - SNS Topic for failure alerts
# Converted from constructs/notification_construct.py

# SNS Topic for failure notifications to SRE team
resource "aws_sns_topic" "notification_topic" {
  name         = "${var.project_name}-failure-notifications"
  display_name = "Lambda Failure Notifications"

  tags = {
    Name        = "FailureNotificationTopic"
    Component   = "Notification"
    Description = "SNS topic for failure notifications to SRE team"
  }
}
