provider "aws" {
  region = "eu-central-1" # Ändern Sie die Region nach Bedarf
}
resource "aws_lambda_function" "example_lambda" {
  function_name = "sensorAuth"
  handler      = "index.handler"
  runtime      = "nodejs18.x" 
  filename     = "lambda.zip" 
  role         = aws_iam_role.lambda_role.arn
}
resource "aws_iam_role" "lambda_role" {
  name = "sensorauthorizor_lambda_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      }
    }
  ]
}
EOF
}

resource "aws_iam_policy" "lambda_policy" {
  name        = "sensorauthorizor_lambda_policy"
  description = "Policy for the example Lambda function"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement" : [
    {
      "Effect" : "Allow",
      "Action" : [
        "dynamodb:PutItem",
        "dynamodb:Query",
        "dynamodb:DeleteItem"

      ],
      "Resource" : "*"
    }
  ]
}
EOF
}

resource "aws_iam_policy_attachment" "lambda_policy_attachment" {
  name       = "sensorauthorizor_lambda_attachment" # Geben Sie hier einen Namen für die Anlage an
  policy_arn = aws_iam_policy.lambda_policy.arn
  roles      = [aws_iam_role.lambda_role.name]
}