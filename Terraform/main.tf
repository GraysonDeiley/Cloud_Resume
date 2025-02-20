terraform {
  required_providers {
    aws = {
      version = "~> 4.0"
      source  = "hashicorp/aws"
    }
  }


}

provider "aws" {
  region = "us-east-1"
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}


# resource "aws_dynamodb_table" "dynamodb_table" {
#   name           = "visitorCounterTwo"
#   billing_mode   = "PROVISIONED"
#   read_capacity  = 20
#   write_capacity = 20
#   hash_key       = "id"

#   attribute {
#     name = "id"
#     type = "S"
#   }

# }

# resource "aws_dynamodb_table_item" "visitor_counter_item" {
#   count = 1  # Adjust the number of items as needed

#   table_name = aws_dynamodb_table.dynamodb_table.name

#   hash_key = "id"

#   item = jsonencode({
#     id = {
#       S = "counter"  # id is explicitly set as a string "counter"
#     }
#     count = {
#       N = tostring(0)  # count is explicitly set as a number (N) with value 81
#     }
#   })
# }



resource "aws_lambda_function" "updateVisitorCountTwo" {
  function_name = "updateVisitorCountTwo"
  runtime       = "python3.9"
  role          = "arn:aws:iam::571600870518:role/service-role/updateVisitorCount-role-ck3bo9nq"
  handler       = "lambda_function.lambda_handler"

  filename         = "/Users/graysondeiley/Desktop/Code_Repo1/Terraform/Cloud_Resume/lambda_function.zip"
  source_code_hash = filebase64sha256("/Users/graysondeiley/Desktop/Code_Repo1/Terraform/Cloud_Resume/lambda_function.zip")

}

resource "aws_api_gateway_rest_api" "my_api" {
  name        = "VisitorCounterApiTwo"
  description = "My API Gateway for counter services"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_resource" "counter" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  parent_id   = aws_api_gateway_rest_api.my_api.root_resource_id
  path_part   = "counter"
}

resource "aws_api_gateway_method" "myMethod" {
  rest_api_id   = aws_api_gateway_rest_api.my_api.id
  resource_id   = aws_api_gateway_resource.counter.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.updateVisitorCountTwo.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.my_api.execution_arn}/GET/counter"
}


resource "aws_api_gateway_integration" "myIntegration" {
  rest_api_id          = aws_api_gateway_rest_api.my_api.id
  resource_id          = aws_api_gateway_resource.counter.id
  http_method          = aws_api_gateway_method.myMethod.http_method
  integration_http_method = "GET"
  type                 = "AWS"
  timeout_milliseconds = 29000
  uri                  = "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/${aws_lambda_function.updateVisitorCountTwo.arn}/invocations"

  depends_on = [aws_api_gateway_method.myMethod]
}

resource "aws_api_gateway_deployment" "deployment" {
  depends_on  = [aws_api_gateway_integration.myIntegration]
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  stage_name  = "prod"
}

output "lambda_function_arn" {
  value = aws_lambda_function.updateVisitorCountTwo.arn
}

output "region" {
  value = data.aws_region.current.name
}