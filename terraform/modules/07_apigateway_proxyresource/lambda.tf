resource "aws_lambda_function" "inner_routing" {
  function_name    = "InnerRoutingFunction"
  s3_bucket        = aws_s3_bucket.lambda_inner_routing.bucket
  s3_key           = aws_s3_object.lambda_inner_routing_object.key
  runtime          = "provided.al2023"
  role             = aws_iam_role.lambda_exec_role.arn
  architectures    = ["arm64"]
  handler          = "bootstrap"
  source_code_hash = filebase64sha256(data.archive_file.lambda_inner_routing.output_path)
}

resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda_exec_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      },
    }]
  })
}

resource "aws_iam_policy_attachment" "lambda_logs_policy_attachment" {
  name       = "lambda-logs-policy-attachment"
  roles      = [aws_iam_role.lambda_exec_role.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_policy_attachment" "lambda_exec_role_policy_attachment" {
  name       = "s3-read-only-access-policy-attachment"
  roles      = [aws_iam_role.lambda_exec_role.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

resource "aws_lambda_permission" "api_gateway_permission" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.inner_routing.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.proxy_sample.execution_arn}/*/*/*"
}
