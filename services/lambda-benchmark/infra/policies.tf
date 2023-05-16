data "aws_iam_policy" "AWSXRayDaemonWriteAccess" {
  name = "AWSXRayDaemonWriteAccess"
}

data "aws_iam_policy" "AWSLambdaBasicExecutionRole" {
  name = "AWSLambdaBasicExecutionRole"
}

# Pode trocar pela policy gerenciada AWSLambdaENIManagementAccess
resource "aws_iam_policy" "ManageNetworkInterface" {
  name        = "ManageNetworkInterface"
  path        = "/lambda-benchmark/"
  description = "Permite que o recurso crie, liste e remova  interfaces de rede"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface",
          "ec2:AssignPrivateIpAddresses",
          "ec2:UnassignPrivateIpAddresses"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}
