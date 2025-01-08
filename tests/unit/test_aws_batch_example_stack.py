import aws_cdk as core
import aws_cdk.assertions as assertions

from aws_batch_example.aws_batch_example_stack import AwsBatchExampleStack

# example tests. To run these tests, uncomment this file along with the example
# resource in aws_batch_example/aws_batch_example_stack.py
def test_sqs_queue_created():
    app = core.App()
    stack = AwsBatchExampleStack(app, "aws-batch-example")
    template = assertions.Template.from_stack(stack)

#     template.has_resource_properties("AWS::SQS::Queue", {
#         "VisibilityTimeout": 300
#     })
