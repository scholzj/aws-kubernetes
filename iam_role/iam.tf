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

#####
# Create the cloud formation which triggers the role creation
#####

resource "aws_cloudformation_stack" "iam_role" {
  name          = "${var.cluster_name}"
  template_url  = "${var.template_url}"

  parameters {
      PolicyName = "${aws_iam_policy.iam_role_policy.name}"
      RoleName = "${var.cluster_name}-tagging-lambda"
      TrustEntity = "lambda.amazonaws.com"
  }

  tags = "${var.tags}"
}
