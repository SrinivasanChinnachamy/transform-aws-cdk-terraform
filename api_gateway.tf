# API Gateway REST API
# Converted from constructs/api_construct.py

# REST API Gateway
resource "aws_api_gateway_rest_api" "data_api" {
  name        = "Data Processing API"
  description = "API for submitting data processing requests"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = {
    Name        = "DataApi"
    Component   = "API"
    Description = "API Gateway for data processing requests"
  }
}

# POST Method on root resource
resource "aws_api_gateway_method" "post_method" {
  rest_api_id   = aws_api_gateway_rest_api.data_api.id
  resource_id   = aws_api_gateway_rest_api.data_api.root_resource_id
  http_method   = "POST"
  authorization = "NONE"
}

# Lambda Integration for POST method
resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.data_api.id
  resource_id             = aws_api_gateway_rest_api.data_api.root_resource_id
  http_method             = aws_api_gateway_method.post_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.api_function.invoke_arn
}

# Lambda permission for API Gateway to invoke the function
resource "aws_lambda_permission" "api_gateway_invoke" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api_function.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.data_api.execution_arn}/*/*"
}

# API Gateway Deployment
resource "aws_api_gateway_deployment" "deployment" {
  rest_api_id = aws_api_gateway_rest_api.data_api.id

  # Trigger redeployment when these resources change
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_rest_api.data_api.body,
      aws_api_gateway_method.post_method.id,
      aws_api_gateway_integration.lambda_integration.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_method.post_method,
    aws_api_gateway_integration.lambda_integration
  ]
}

# API Gateway Stage
resource "aws_api_gateway_stage" "prod" {
  deployment_id = aws_api_gateway_deployment.deployment.id
  rest_api_id   = aws_api_gateway_rest_api.data_api.id
  stage_name    = "prod"

  tags = {
    Name        = "ProdStage"
    Component   = "API"
    Environment = "production"
  }
}
