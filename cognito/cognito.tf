provider "aws" {
  region = "eu-central-1" # Ändern Sie die Region nach Bedarf
}


resource "aws_cognito_user_pool" "example" {
  name = "my-user-pool"
}

resource "aws_cognito_user_pool_client" "example" {
  name = "my-app-client"
  user_pool_id = aws_cognito_user_pool.example.id
}

data "aws_region" "current"{}

output cognito_arn {
  value       = "arn:aws:cognito-idp:${data.aws_region.current.name}:508546100226:userpool/${aws_cognito_user_pool.example.id}"
  sensitive   = false
  description = "ARN of the Cognito Pool"
  depends_on  = []
}






