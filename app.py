#!/usr/bin/env python3
import os
import aws_cdk as cdk
from event_driven_stack import EventDrivenStack

app = cdk.App()
EventDrivenStack(app, "EventDrivenStack",
    env=cdk.Environment(
        account=os.getenv('CDK_DEFAULT_ACCOUNT'),
        region=os.getenv('CDK_DEFAULT_REGION')
    )
)

app.synth()
