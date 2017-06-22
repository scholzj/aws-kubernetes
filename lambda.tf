#####
# Creates the tagging lambda
#####

#####
# IAM role
#####
data "aws_iam_role" "iam_role" {
  role_name = "${var.dbg_naming_prefix}${var.cluster_name}-tagging-lambda"
}

#####
# Lambda Function
#####

# Generate ZIP archive with Lambda

data "template_file" "lambda" {
    template = "${file("${path.module}/template/tagging_lambda.py")}"
    
    vars {
      aws_region = "${var.aws_region}"
      cluster_name = "${var.cluster_name}"
      tags = "${jsonencode(var.tags)}"
      timestamp = "${timestamp()}"
    }
}

resource "null_resource" "zip_lambda" {
  triggers {
    template_rendered = "${ data.template_file.lambda.rendered }"
  }

  provisioner "local-exec" {
    command = "cat << EOF > /tmp/tagging_lambda.py\n${ data.template_file.lambda.rendered }\nEOF"
  }

  provisioner "local-exec" {
    command = "zip -j /tmp/tagging_lambda /tmp/tagging_lambda.py"
  }
}

# Create lambda

resource "aws_lambda_function" "tagging" {
  depends_on = ["data.aws_iam_role.iam_role", "null_resource.zip_lambda"]

  filename      = "/tmp/tagging_lambda.zip"
  function_name = "${var.cluster_name}-tagging-lambda"
  role          = "${data.aws_iam_role.iam_role.arn}"
  handler       = "tagging_lambda.lambda_handler"
  runtime       = "python2.7"
  timeout       = "60"
  memory_size   = "128"

  tags = "${var.tags}"
}

resource "aws_cloudwatch_event_rule" "tagging" {
  name        = "${var.cluster_name}-tagging-lambda"
  description = "Trigger tagging lambda in periodical intervals"
  schedule_expression = "rate(5 minutes)"
}

resource "aws_lambda_permission" "tagging" {
  statement_id   = "${var.cluster_name}-AllowCloudWatchTrigger"
  action         = "lambda:InvokeFunction"
  function_name  = "${aws_lambda_function.tagging.function_name}"
  principal      = "events.amazonaws.com"
  source_arn     = "${aws_cloudwatch_event_rule.tagging.arn}"
}

resource "aws_cloudwatch_event_target" "tagging" {
  rule      = "${aws_cloudwatch_event_rule.tagging.name}"
  target_id = "${var.cluster_name}-TriggerLambda"
  arn       = "${aws_lambda_function.tagging.arn}"
}