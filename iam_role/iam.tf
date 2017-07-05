#####
# Create the policy document
#####

data "template_file" "policy_json" {
  template = "${file("${path.module}/template/policy.json.tpl")}"

  vars {}
}

resource "aws_iam_policy" "iam_role_policy" {
  name        = "${var.dbg_naming_prefix}${var.cluster_name}"
  path        = "/"
  description = "Policy for role ${var.dbg_naming_prefix}${var.cluster_name}"
  policy      = "${data.template_file.policy_json.rendered}"
}

#####
# Create the cloud formation which triggers the role creation
#####

resource "aws_cloudformation_stack" "iam_role" {
  name          = "${var.cluster_name}"
  template_url  = "${var.template_url}"

  parameters {
      PolicyName = "${var.dbg_naming_prefix}${var.cluster_name}"
      RoleName = "${var.cluster_name}"
      TrustEntity = "ec2.amazonaws.com"
  }

  tags = "${merge(map("Name", var.cluster_name), var.tags)}"
}
