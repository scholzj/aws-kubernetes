#####
# IAM role
#####

# Master

data "aws_iam_role" "master_role" {
  role_name = "${var.dbg_naming_prefix}${var.cluster_name}-master"
}

# Worker

data "aws_iam_role" "node_role" {
  role_name = "${var.dbg_naming_prefix}${var.cluster_name}-node"
}