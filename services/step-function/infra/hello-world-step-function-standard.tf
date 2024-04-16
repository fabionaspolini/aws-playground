resource "aws_sfn_state_machine" "hello_world_standard" {
  name     = "hello-world-standard"
  role_arn = aws_iam_role.hello_world_standard.arn
  type     = "STANDARD"

  logging_configuration {
    log_destination        = "${aws_cloudwatch_log_group.hello_world_standard.arn}:*"
    include_execution_data = true
    level                  = "ERROR" # ALL, ERROR, CRITICAL, OFF
  }

  definition = <<EOF
{
  "Comment": "A Hello World example demonstrating various state types of the Amazon States Language. It is composed of flow control states only, so it does not need resources to run.",
  "StartAt": "Pass",
  "States": {
    "Pass": {
      "Comment": "A Pass state passes its input to its output, without performing work. They can also generate static JSON output, or transform JSON input using filters and pass the transformed data to the next state. Pass states are useful when constructing and debugging state machines.",
      "Type": "Pass",
      "Result": {
        "IsHelloWorldExample": true
      },
      "Next": "Hello World example?"
    },
    "Hello World example?": {
      "Comment": "A Choice state adds branching logic to a state machine. Choice rules can implement many different comparison operators, and rules can be combined using And, Or, and Not",
      "Type": "Choice",
      "Choices": [
        {
          "Variable": "$.IsHelloWorldExample",
          "BooleanEquals": true,
          "Next": "Yes"
        },
        {
          "Variable": "$.IsHelloWorldExample",
          "BooleanEquals": false,
          "Next": "No"
        }
      ],
      "Default": "Yes"
    },
    "Yes": {
      "Type": "Pass",
      "Next": "Wait 3 sec"
    },
    "No": {
      "Type": "Fail",
      "Cause": "Not Hello World"
    },
    "Wait 3 sec": {
      "Comment": "A Wait state delays the state machine from continuing for a specified time.",
      "Type": "Wait",
      "Seconds": 3,
      "Next": "Parallel State"
    },
    "Parallel State": {
      "Comment": "A Parallel state can be used to create parallel branches of execution in your state machine.",
      "Type": "Parallel",
      "Next": "Hello World",
      "Branches": [
        {
          "StartAt": "Hello",
          "States": {
            "Hello": {
              "Type": "Pass",
              "End": true
            }
          }
        },
        {
          "StartAt": "World",
          "States": {
            "World": {
              "Type": "Pass",
              "End": true
            }
          }
        }
      ]
    },
    "Hello World": {
      "Type": "Pass",
      "End": true
    }
  }
}
EOF
}

resource "aws_cloudwatch_log_group" "hello_world_standard" {
  name              = "/aws/vendedlogs/states/aws-playground/services/step-function/hello-world-standard"
  retention_in_days = 1
}

resource "aws_iam_role" "hello_world_standard" {
  name = "hello-world-standard-state-machine"
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
    aws_iam_policy.state_machine_x_ray.arn
  ]
}
