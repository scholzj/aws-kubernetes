#####
# Create master role
#####

data "template_file" "master_policy_json" {
    template = "${file("${path.module}/policy/master-policy.json.tpl")}"

    vars {}
}

resource "aws_iam_policy" "master_role_policy" {
    name        = "${var.dbg_naming_prefix}${var.cluster_name}-master"
    path        = "/"
    description = "Policy for role ${var.dbg_naming_prefix}${var.cluster_name}-master"
    policy      = "${data.template_file.master_policy_json.rendered}"
}

resource "aws_iam_role" "master_role" {
    name                  = "${var.dbg_naming_prefix}${var.cluster_name}-master"
    force_detach_policies = true
    assume_role_policy    = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy_attachment" "master-policy-attach" {
    name       = "${var.dbg_naming_prefix}${var.cluster_name}-master-attachment"
    roles      = [ "${aws_iam_role.master_role.name}" ]
    policy_arn = "${aws_iam_policy.master_role_policy.arn}"
}

resource "aws_iam_instance_profile" "master_instance_profile" {
    name = "${var.dbg_naming_prefix}${var.cluster_name}-master"
    role = "${aws_iam_role.master_role.name}"
}

#####
# Create node role
#####

data "template_file" "node_policy_json" {
    template = "${file("${path.module}/policy/node-policy.json.tpl")}"

    vars {}
}

resource "aws_iam_policy" "node_role_policy" {
    name        = "${var.dbg_naming_prefix}${var.cluster_name}-node"
    path        = "/"
    description = "Policy for role ${var.dbg_naming_prefix}${var.cluster_name}-node"
    policy      = "${data.template_file.node_policy_json.rendered}"
}

resource "aws_iam_role" "node_role" {
    name                  = "${var.dbg_naming_prefix}${var.cluster_name}-node"
    force_detach_policies = true
    assume_role_policy    = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy_attachment" "node-policy-attach" {
    name       = "${var.dbg_naming_prefix}${var.cluster_name}-node-attachment"
    roles      = [ "${aws_iam_role.node_role.name}" ]
    policy_arn = "${aws_iam_policy.node_role_policy.arn}"
}

resource "aws_iam_instance_profile" "node_instance_profile" {
    name = "${var.dbg_naming_prefix}${var.cluster_name}-node"
    role = "${aws_iam_role.node_role.name}"
}

#####
# Create tagging lambda role
#####

data "template_file" "lambda_policy_json" {
    template = "${file("${path.module}/policy/lambda-policy.json.tpl")}"

    vars {}
}

resource "aws_iam_policy" "lambda_role_policy" {
    name        = "${var.dbg_naming_prefix}${var.cluster_name}-tagging-lambda"
    path        = "/"
    description = "Policy for role ${var.dbg_naming_prefix}${var.cluster_name}-tagging-lambda"
    policy      = "${data.template_file.lambda_policy_json.rendered}"
}

resource "aws_iam_role" "lambda_role" {
    name                  = "${var.dbg_naming_prefix}${var.cluster_name}-tagging-lambda"
    force_detach_policies = true
    assume_role_policy    = <<EOF
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

resource "aws_iam_policy_attachment" "lambda-policy-attach" {
    name       = "${var.dbg_naming_prefix}${var.cluster_name}-tagging-lambda"
    roles      = [ "${aws_iam_role.lambda_role.name}" ]
    policy_arn = "${aws_iam_policy.lambda_role_policy.arn}"
}
