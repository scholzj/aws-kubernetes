#####
# Create the policy document
#####

data "template_file" "policy_json" {
  template = "${file("${path.module}/template/policy.json.tpl")}"

  vars {}
}

resource "aws_iam_policy" "iam_role_policy" {
  name        = "${var.dbg_naming_prefix}${var.cluster_name}-tagging-lambda"
  path        = "/"
  description = "Policy for role ${var.dbg_naming_prefix}${var.cluster_name}-tagging-lambda"
  policy      = "${data.template_file.policy_json.rendered}"
}

resource "aws_iam_role" "iam_role" {
  name = "${var.dbg_naming_prefix}${var.cluster_name}-tagging-lambda"
  force_detach_policies = true
  assume_role_policy = <<EOF
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
EOF
}

resource "aws_iam_policy_attachment" "policy-attach" {
  name       = "${var.dbg_naming_prefix}${var.cluster_name}-tagging-lambda"
  roles      = ["${aws_iam_role.iam_role.name}"]
  policy_arn = "${aws_iam_policy.iam_role_policy.arn}"
}
