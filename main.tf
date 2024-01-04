provider "aws" {
  region = "eu-central-1" # Ändern Sie die Region nach Bedarf
}

data "aws_region" "current" {}

resource "aws_iam_role" "api_gateway_execution_role" {
  name = "api_gateway_execution_role"

  assume_role_policy = <<POLICY1
{
  "Version" : "2012-10-17",
  "Statement" : [
    {
      "Effect" : "Allow",
      "Principal" : {
        "Service" : "apigateway.amazonaws.com"
      },
      "Action" : "sts:AssumeRole"
    }
  ]
}
POLICY1
}

# Create an IAM policy for API Gateway to PutItem & Query DynamoDB
resource "aws_iam_policy" "APIGWPolicy" {
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "dynamodb:PutItem",
          "dynamodb:Query",
        ],
        Resource = [
          aws_dynamodb_table.sensor_table.arn,
          "${aws_dynamodb_table.sensor_table.arn}/index/*"
        ]
      },
      {
        Effect   = "Allow",
        Action   = [
          "lambda:InvokeFunction",
          ],
        Resource = aws_lambda_function.example_lambda.arn
      }
    ]
  })
}


# Attach the IAM policies to the equivalent role
resource "aws_iam_role_policy_attachment" "APIGWPolicyAttachment" {
  role       = aws_iam_role.api_gateway_execution_role.name
  policy_arn = aws_iam_policy.APIGWPolicy.arn
}


resource "aws_dynamodb_table" "sensor_table" {
  name           = "sensor-table"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"
  attribute {
    name = "id"
    type = "S"
  }
  attribute {
    name = "sub_string"
    type = "S"
  }
  global_secondary_index {
    name               = "sub-gsi"
    hash_key           = "sub_string" # Ändern Sie dies entsprechend Ihrem Attributnamen
    projection_type    = "ALL"      # Ändern Sie dies entsprechend Ihren Anforderungen (z.B. "INCLUDE" für spezifische Attribute)
    read_capacity      = 5
    write_capacity     = 5
  }
}

resource "aws_api_gateway_rest_api" "MyApiGatewayRestApi" {
  name = "APIGW DynamoDB Serverless Pattern Demo"
}

resource "aws_api_gateway_resource" "sensor" {
  rest_api_id = aws_api_gateway_rest_api.MyApiGatewayRestApi.id
  parent_id   = aws_api_gateway_rest_api.MyApiGatewayRestApi.root_resource_id
  path_part   = "sensor"
}

resource "aws_api_gateway_resource" "id" {
  rest_api_id = aws_api_gateway_rest_api.MyApiGatewayRestApi.id
  parent_id   = aws_api_gateway_resource.sensor.id
  path_part   = "{id}"
}











/*
resource "aws_iam_policy" "cognito_policy" {
  name        = "lambda-cognito-policy"
  description = "Policy to allow Lambda to interact with Cognito"
  
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "cognito-idp:AdminInitiateAuth",
          "cognito-idp:AdminRespondToAuthChallenge",
          "cognito-idp:AdminUpdateUserAttributes",
          "cognito-idp:ListUsers"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cognito_policy_attachment" {
  policy_arn = aws_iam_policy.cognito_policy.arn
  role       = aws_iam_role.api_gateway_execution_role.name
}
*/


/*
"x-amazon-apigateway-integration" : {
            "credentials": "${aws_iam_role.api_gateway_execution_role.arn}",
            "type" : "AWS_PROXY", // Ändern Sie den Integrationstyp auf AWS_PROXY
            "httpMethod" : "POST",
            "uri" : aws_lambda_function.example_lambda.invoke_arn,
            "authorizerId" : aws_api_gateway_authorizer.cognito_authorizer.id, // Verweisen Sie auf die Lambda-Funktion
            
          }
*/

/*"responses" : {
              "default" : {
                "statusCode" : "200",
                "responseTemplates" : {
                  "application/json" : "{\"id\": \"$input.path('$.id')\", \"name\": \"$input.path('$.name')\", \"template\": \"$input.path('$.template')\"}"
                }
              }
            },
            "requestTemplates" : {
              "application/json" : "{\"type\": \"UNAUTHORIZED\", \"params\":{\"TableName\":\"sensor-table\",\"Item\":{\"id\":\"$context.requestId\",\"name\":\"$input.path('$.name')\",\"template\":\"$input.path('$.template')\"}}}",
            },
            "passthroughBehavior" : "when_no_match", // Ändern Sie passthroughBehavior auf "when_no_match"
            */