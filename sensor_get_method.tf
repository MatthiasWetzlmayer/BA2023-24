resource "aws_api_gateway_method" "get_method" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.sensor.id
  http_method   = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id    = aws_api_gateway_authorizer.cognito_authorizer.id
}


resource "aws_api_gateway_integration" "get_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.sensor.id
  http_method             = aws_api_gateway_method.get_method.http_method
  integration_http_method = "POST"
  type                    = "AWS"
  uri                     = "arn:aws:apigateway:${data.aws_region.current.name}:dynamodb:action/Query" 
  credentials             = aws_iam_role.api_gateway_execution_role.arn
  request_templates = {
    "application/json" = <<EOF
       {
      "TableName": "sensor-table",
      "IndexName": "sub-gsi",
      "KeyConditionExpression": "sub_string = :val",
      "ExpressionAttributeValues": {
        ":val": {
          "S": "$context.authorizer.claims.sub"
        }
      }
    }
        EOF
  }

}

resource "aws_api_gateway_integration_response" "get_integration_response" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.sensor.id
  http_method             = aws_api_gateway_method.get_method.http_method
  status_code             = 200

  # Transforms the backend JSON response to XML
  response_templates = {
    "application/json" = <<EOF
    #set($inputRoot = $input.path('$'))
    [
      #foreach($item in $inputRoot.Items)
        {
          "sensor_name": "$item.sensor_name.S",
          "template": "$item.template.S"
        }#if($foreach.hasNext),#end
      #end
    ]
    EOF
  }


  depends_on = [
    aws_api_gateway_integration.get_integration
  ]
}

resource "aws_api_gateway_method_response" "get_response" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.sensor.id
  http_method             = aws_api_gateway_method.get_method.http_method
  status_code = aws_api_gateway_integration_response.get_integration_response.status_code
  response_models = {
    "application/json" = "Empty"
  }
}