resource "aws_api_gateway_authorizer" "cognito_authorizer" {
  name                   = "cognito-authorizer"
  rest_api_id            = aws_api_gateway_rest_api.MyApiGatewayRestApi.id
  authorizer_credentials = aws_iam_role.api_gateway_execution_role.arn
  identity_source        = "method.request.header.Authorization"
  type                   = "COGNITO_USER_POOLS"
  provider_arns          = ["arn:aws:cognito-idp:eu-central-1:508546100226:userpool/eu-central-1_aUy4duruG"]
}