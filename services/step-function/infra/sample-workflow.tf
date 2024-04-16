resource "aws_sfn_state_machine" "sample_work_flow" {
  name     = "sample-workflow"
  role_arn = aws_iam_role.sample_work_flow.arn
  type     = "EXPRESS"

  logging_configuration {
    log_destination        = "${aws_cloudwatch_log_group.sample_work_flow.arn}:*"
    include_execution_data = true
    level                  = "ALL" # ALL, ERROR, CRITICAL, OFF
  }

  definition = <<EOF
{
  "Comment": "A description of my state machine",
  "StartAt": "String Upper Case",
  "States": {
    "String Upper Case": {
      "Type": "Task",
      "Resource": "arn:aws:states:::lambda:invoke",
      "OutputPath": "$.Payload",
      "Parameters": {
        "FunctionName": "arn:aws:lambda:us-east-1:452970698287:function:string-upper-case-to-step-function-sample:$LATEST",
        "Payload": {
          "value.$": "$.inputText"
        }
      },
      "Retry": [
        {
          "ErrorEquals": [
            "Lambda.ServiceException",
            "Lambda.AWSLambdaException",
            "Lambda.SdkClientException",
            "Lambda.TooManyRequestsException"
          ],
          "IntervalSeconds": 1,
          "MaxAttempts": 3,
          "BackoffRate": 2
        }
      ],
      "End": true
    }
  }
}
EOF
}

resource "aws_cloudwatch_log_group" "sample_work_flow" {
  name              = "/aws/vendedlogs/states/aws-playground/services/step-function/sample-workflow"
  retention_in_days = 1
}

resource "aws_iam_role" "sample_work_flow" {
  name = "sample-workflow-state-machine"
  path = "/aws-playground/services/step-function/"

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "states.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })

  managed_policy_arns = [
    aws_iam_policy.state_machine_logs_delivery_full_access.arn,
    aws_iam_policy.state_machine_x_ray.arn,
    aws_iam_policy.state_machine_lambda_invoke.arn
  ]
}
