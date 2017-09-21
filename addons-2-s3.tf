resource "random_shuffle" "addons_bucket" {
    input        = [ "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "a", "b", "c", "d", "e", "f", "g", "h", "i", "t",
        "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z" ]
    result_count = 6
}

locals {
    addons_bucket_name = "${var.cluster_name}-addons-${join("", random_shuffle.addons_bucket.result)}"
}


data "template_file" "addons_bucket_policy" {
    template = "${file("${path.module}/policy/addons-bucket-policy.json.tpl")}"

    vars {
        bucket_name     = "${local.addons_bucket_name}"
        node_role_arn   = "${aws_iam_role.node_role.arn}"
        master_role_arn = "${aws_iam_role.master_role.arn}"
    }
}

resource "aws_s3_bucket" "addons_bucket" {
    bucket = "${local.addons_bucket_name}"
    policy = "${data.template_file.addons_bucket_policy.rendered}"
    acl    = "private"

    tags   = "${local.cluster_tags}"
}

locals {
    addons_bucket_url = "s3://${aws_s3_bucket.addons_bucket.bucket}"
}

# Render values for addons

# Autoscaler addon

# Worker nodes array into cluster-autoscaler formatted strings
resource "null_resource" "asg_node" {
    count = "${length(var.worker_instances)}"

    triggers {
        asg_node = "- name: ${var.cluster_name}-${lookup(var.worker_instances[count.index], "instance_type")}-nodes\n  minSize: ${lookup(var.worker_instances[count.index], "min_instance_count")}\n  maxSize: ${lookup(var.worker_instances[count.index], "max_instance_count")}"
    }
}

data "template_file" "cluster-autoscaler-default-values-yaml" {
    template = "${file("${path.module}/addons/cluster-autoscaler/default-values.yaml.tpl")}"

    vars {
        aws_region = "${var.aws_region}"
        asg_nodes  = "${indent(2, join("\n", null_resource.asg_node.*.triggers.asg_node))}"
    }
}

resource "local_file" "cluster-autoscaler-default-values-yaml" {
    content  = "${data.template_file.cluster-autoscaler-default-values-yaml.rendered}"
    filename = "${path.module}/addons/cluster-autoscaler/default-values.yaml"
}

# External DNS addon

data "template_file" "external-dns-default-values-yaml" {
    template = "${file("${path.module}/addons/external-dns/default-values.yaml.tpl")}"

    vars {
        cluster_name = "${var.cluster_name}"
    }
}

resource "local_file" "external-dns-default-values-yaml" {
    content  = "${data.template_file.external-dns-default-values-yaml.rendered}"
    filename = "${path.module}/addons/external-dns/default-values.yaml"
}

# Archive addons
data "archive_file" "zip_addons" {
    type        = "zip"
    source_dir  = "${path.module}/addons/"
    output_path = "${path.module}/.tmp/addons.zip"

    depends_on = [
        "local_file.cluster-autoscaler-default-values-yaml",
        "local_file.external-dns-default-values-yaml"
    ]
}

resource "aws_s3_bucket_object" "addons" {
    bucket                 = "${aws_s3_bucket.addons_bucket.bucket}"
    key                    = "addons.zip"
    source                 = "${data.archive_file.zip_addons.output_path}"

    acl                    = "private"
    server_side_encryption = "aws:kms"
    tags                   = "${local.cluster_tags}"
}

locals {
    addons_zip_url = "${local.addons_bucket_url}/${aws_s3_bucket_object.addons.key}"
}
