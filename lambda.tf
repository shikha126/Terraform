resource "aws_lambda_function" "lambda_tf_function" {
  filename      = "lambda.zip"
  function_name = "lambda_handler"
  role          = "${aws_iam_role.lambda_tf_role.arn}"
  handler       = "lambda.lambda_handler"
  runtime = "python3.8"
  # The filebase64sha256() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the base64sha256() function and the file() function:
  # source_code_hash = "${base64sha256(file("lambda_function_payload.zip"))}"
  source_code_hash = "${filebase64sha256("lambda.zip")}"
  depends_on = ["aws_iam_role.lambda_tf_role"]
}

resource "aws_iam_role" "lambda_tf_role" {
    name = "lambda_tf_role"
    assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
POLICY

  tags = {
    tag-key = "lambda_tf_role"
  }
}

resource "aws_iam_policy" "lambda_tf_policy" {
  name        = "lambda_tf_policy"
  path        = "/"
  description = "lambda_tf_policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
            "Action": "ec2:*",
            "Effect": "Allow",
            "Resource": "*"
    },
    {
      "Action": [
         "logs:CreateLogStream",
         "logs:PutLogEvents"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:logs:*:*:*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "test-attach" {
  role       = "${aws_iam_role.lambda_tf_role.name}"
  policy_arn = "${aws_iam_policy.lambda_tf_policy.arn}"
}

resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name              = "/aws/lambda/${aws_lambda_function.lambda_tf_function.function_name}"
  retention_in_days = 14
  depends_on = ["aws_lambda_function.lambda_tf_function"]
}
