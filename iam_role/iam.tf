#####
# Create the policy document - Master node
#####

data "template_file" "master_policy_json" {
  template = "${file("${path.module}/template/master-policy.json.tpl")}"

  vars {}
}

resource "aws_iam_policy" "master_role_policy" {
  name        = "${var.dbg_naming_prefix}${var.cluster_name}-master"
  path        = "/"
  description = "Policy for role ${var.dbg_naming_prefix}${var.cluster_name}-master"
  policy      = "${data.template_file.master_policy_json.rendered}"
}

#####
# Create the cloud formation which triggers the role creation - Master node
#####

resource "aws_cloudformation_stack" "master_role" {
  name          = "${var.cluster_name}-master"
  template_url  = "${var.template_url}"

  parameters {
      PolicyName = "${var.dbg_naming_prefix}${var.cluster_name}-master"
      RoleName = "${var.cluster_name}-master"
      TrustEntity = "ec2.amazonaws.com"
  }

  tags = "${merge(map("Name", var.cluster_name), var.tags)}"
}

#####
# Create the policy document - Worker nodes
#####

data "template_file" "node_policy_json" {
  template = "${file("${path.module}/template/node-policy.json.tpl")}"

  vars {}
}

resource "aws_iam_policy" "node_role_policy" {
  name        = "${var.dbg_naming_prefix}${var.cluster_name}-node"
  path        = "/"
  description = "Policy for role ${var.dbg_naming_prefix}${var.cluster_name}-node"
  policy      = "${data.template_file.node_policy_json.rendered}"
}

#####
# Create the cloud formation which triggers the role creation - Worker nodes
#####

resource "aws_cloudformation_stack" "node_role" {
  name          = "${var.cluster_name}-node"
  template_url  = "${var.template_url}"

  parameters {
      PolicyName = "${var.dbg_naming_prefix}${var.cluster_name}-node"
      RoleName = "${var.cluster_name}-node"
      TrustEntity = "ec2.amazonaws.com"
  }

  tags = "${merge(map("Name", var.cluster_name), var.tags)}"
}