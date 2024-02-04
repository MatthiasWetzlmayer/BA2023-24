provider "aws" {
  region = "eu-central-1" # Ändern Sie die Region nach Bedarf
}


# Lambda-Funktion, die Benutzer automatisch bestätigt
resource "aws_lambda_function" "auto_confirm_user" {
  filename         = "../lambda/cognito_presignup/lambda.zip"
  function_name    = "autoConfirmUser"
  role             = aws_iam_role.lambda_exec_role.arn
  handler          = "index.handler"
  runtime          = "nodejs18.x"
  
  // Weitere Konfigurationen...
}

# IAM-Rolle für die Lambda-Funktion
resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda_cognito_presign_exec_role"

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


resource "aws_cognito_user_pool" "userpool" {
  name = "mein-user-pool"

  auto_verified_attributes = ["email"]

  # Schemas für Benutzerattribute
  schema {
    attribute_data_type      = "String"
    name                     = "email"
    required                 = true
    string_attribute_constraints {
      min_length            = 7
    }
  }

  password_policy {
    minimum_length    = 8
  }

  # Verhindern, dass Benutzer bei der ersten Anmeldung ihr Passwort ändern müssen
  admin_create_user_config {
    allow_admin_create_user_only = false
  }

  lambda_config {
    pre_sign_up = aws_lambda_function.auto_confirm_user.arn
  }
}

resource "aws_lambda_permission" "allow_cognito_to_invoke_lambda" {
  statement_id  = "AllowExecutionFromCognito"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.auto_confirm_user.function_name
  principal     = "cognito-idp.amazonaws.com"
  source_arn    = aws_cognito_user_pool.userpool.arn
}

resource "aws_cognito_user_pool_client" "userpool_client" {
  name = "my-app-client"
  user_pool_id = aws_cognito_user_pool.userpool.id
}

data "aws_region" "current"{}

output cognito_arn {
  value       = "arn:aws:cognito-idp:${data.aws_region.current.name}:508546100226:userpool/${aws_cognito_user_pool.userpool.id}"
  sensitive   = false
  description = "Cognito Pool for Usermanagement"
  depends_on  = []
}






