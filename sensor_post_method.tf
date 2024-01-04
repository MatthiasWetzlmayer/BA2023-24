resource "aws_api_gateway_method" "post_method" {
  rest_api_id   = aws_api_gateway_rest_api.MyApiGatewayRestApi.id
  resource_id   = aws_api_gateway_resource.sensor.id
  http_method   = "POST"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id    = aws_api_gateway_authorizer.cognito_authorizer.id
}

resource "aws_api_gateway_integration" "lambda_post_integration" {
  rest_api_id             = aws_api_gateway_rest_api.MyApiGatewayRestApi.id
  resource_id             = aws_api_gateway_resource.sensor.id
  http_method             = aws_api_gateway_method.post_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.example_lambda.invoke_arn # Verweisen Sie auf Ihre Lambda-Funktion
  credentials             = aws_iam_role.api_gateway_execution_role.arn
}