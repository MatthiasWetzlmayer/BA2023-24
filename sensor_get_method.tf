resource "aws_api_gateway_method" "get_method" {
  rest_api_id   = aws_api_gateway_rest_api.MyApiGatewayRestApi.id
  resource_id   = aws_api_gateway_resource.sensor.id
  http_method   = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id    = aws_api_gateway_authorizer.cognito_authorizer.id
}


resource "aws_api_gateway_integration" "get_integration" {
  rest_api_id             = aws_api_gateway_rest_api.MyApiGatewayRestApi.id
  resource_id             = aws_api_gateway_resource.sensor.id
  http_method             = aws_api_gateway_method.get_method.http_method
  integration_http_method = "POST"
  type                    = "AWS"
  uri                     = "arn:aws:apigateway:${data.aws_region.current.name}:dynamodb:action/Query" # Verweisen Sie auf Ihre Lambda-Funktion
  credentials             = aws_iam_role.api_gateway_execution_role.arn
  request_templates = {
    "application/json" = <<EOF
    {
      "TableName": "sensor-table",
      "IndexName": "sub-gsi",
      "KeyConditionExpression": "sub_string = :val",
      "ExpressionAttributeValues": {
        ":val": {
          "S": "fe409090-a5c5-40cc-8d40-d044ad5920eb"
        }
      }
    }
        EOF
  }

}

resource "aws_api_gateway_integration_response" "get_integration_response" {
  rest_api_id             = aws_api_gateway_rest_api.MyApiGatewayRestApi.id
  resource_id             = aws_api_gateway_resource.sensor.id
  http_method             = aws_api_gateway_method.get_method.http_method
  status_code             = 200

  # Transforms the backend JSON response to XML
  response_templates = {
    "application/json" = <<EOF
    #set($inputRoot = $input.path('$'))
    "items": [
      #foreach($field in $inputRoot.Items){
        "id": "$field.id.S",
        "name": "$field.name.S",
        "template": "$field.template.S"
        #if($foreach.hasNext),#end
      }
    ]

    EOF
  }
#        "#set($inputRoot = $input.path('$'))\n{\n\t\"pets\": [\n\t\t#foreach($field in $inputRoot.Items) {\n\t\t\t\"id\": \"$field.id.S\"}#if($foreach.hasNext),#end\n\t\t#end\n\t]\n}"


  depends_on = [
    aws_api_gateway_integration.get_integration
  ]
}

resource "aws_api_gateway_method_response" "example" {
  rest_api_id             = aws_api_gateway_rest_api.MyApiGatewayRestApi.id
  resource_id             = aws_api_gateway_resource.sensor.id
  http_method             = aws_api_gateway_method.get_method.http_method
  status_code = aws_api_gateway_integration_response.get_integration_response.status_code
  response_models = {
    "application/json" = "Empty"
  }
}