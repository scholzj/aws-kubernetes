#####
# Creates the tagging lambda function
#####

# Generate ZIP archive with Lambda

data "template_file" "lambda" {
    template = "${file("${path.module}/scripts/tagging_lambda.py.tpl")}"

    vars {
        aws_region   = "${var.aws_region}"
        cluster_name = "${var.cluster_name}"
        tags         = "${jsonencode(var.tags)}"
        timestamp    = "${timestamp()}"
    }
}

data "archive_file" "zip_lambda" {
    type                    = "zip"
    source_content_filename = "tagging_lambda.py"
    source_content          = "${ data.template_file.lambda.rendered }"
    output_path             = "${path.module}/.tmp/tagging_lambda.zip"
}

# Create lambda

resource "aws_lambda_function" "tagging" {
    depends_on    = [ "data.archive_file.zip_lambda" ]

    filename      = "${data.archive_file.zip_lambda.output_path}"
    function_name = "${var.cluster_name}-tagging-lambda"
    role          = "${aws_iam_role.lambda_role.arn}"
    handler       = "tagging_lambda.lambda_handler"
    runtime       = "python2.7"
    timeout       = "60"
    memory_size   = "128"

    tags          = "${var.tags}"
}

resource "aws_cloudwatch_event_rule" "tagging" {
    name                = "${var.cluster_name}-tagging-lambda"
    description         = "Trigger tagging lambda in periodical intervals"
    schedule_expression = "rate(5 minutes)"
}

resource "aws_lambda_permission" "tagging" {
    statement_id  = "${var.cluster_name}-AllowCloudWatchTrigger"
    action        = "lambda:InvokeFunction"
    function_name = "${aws_lambda_function.tagging.function_name}"
    principal     = "events.amazonaws.com"
    source_arn    = "${aws_cloudwatch_event_rule.tagging.arn}"
}

resource "aws_cloudwatch_event_target" "tagging" {
    rule      = "${aws_cloudwatch_event_rule.tagging.name}"
    target_id = "${var.cluster_name}-TriggerLambda"
    arn       = "${aws_lambda_function.tagging.arn}"
}