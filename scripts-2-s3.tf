resource "random_shuffle" "scripts_bucket" {
    input        = [ "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "a", "b", "c", "d", "e", "f", "g", "h", "i", "t",
        "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z" ]
    result_count = 6
}

locals {
    scripts_bucket_name = "${var.cluster_name}-scripts-${join("", random_shuffle.scripts_bucket.result)}"
}


data "template_file" "scripts_bucket_policy" {
    template = "${file("${path.module}/template/scripts-bucket-policy.json.tpl")}"

    vars {
        bucket_name = "${local.scripts_bucket_name}"
        node_role_arn = "${aws_iam_role.node_role.arn}"
        master_role_arn = "${aws_iam_role.master_role.arn}"
    }
}

resource "aws_s3_bucket" "scripts_bucket" {
    bucket = "${local.scripts_bucket_name}"
    policy = "${data.template_file.scripts_bucket_policy.rendered}"
    acl    = "private"

    tags   = "${local.cluster_tags}"
}

locals {
    scripts_bucket_url = "s3://${aws_s3_bucket.scripts_bucket.bucket}"
}

################
# Calico
################

resource "aws_s3_bucket_object" "calico_yaml" {
    bucket                 = "${aws_s3_bucket.scripts_bucket.bucket}"
    key                    = "calico.yaml"
    source                 = "scripts/calico.yaml"

    acl                    = "private"
    server_side_encryption = "aws:kms"
    tags                   = "${local.cluster_tags}"
}

locals {
    calico_yaml_url = "${local.scripts_bucket_url}/${aws_s3_bucket_object.calico_yaml.key}"
}

################
# Node init
################

data "template_file" "init-aws-kubernetes-node" {
    template = "${file("${path.module}/scripts/init-aws-kubernetes-node.sh.tpl")}"

    vars {
        kubeadm_token = "${data.template_file.kubeadm_token.rendered}"
        dns_name      = "${var.cluster_name}.${var.hosted_zone}"
    }
}

resource "aws_s3_bucket_object" "init-aws-kubernetes-node" {
    bucket                 = "${aws_s3_bucket.scripts_bucket.bucket}"
    key                    = "init-aws-kubernetes-node.sh"
    content                = "${data.template_file.init-aws-kubernetes-node.rendered}"

    acl                    = "private"
    server_side_encryption = "aws:kms"
    tags                   = "${local.cluster_tags}"
}

locals {
    init_node_url = "${local.scripts_bucket_url}/${aws_s3_bucket_object.init-aws-kubernetes-node.key}"
}

################
# Autoscaler
################

# Worker nodes array into cluster-autoscaler formated strings.
resource "null_resource" "asg_node" {
    count = "${length(var.worker_instances)}"

    triggers {
        asg_node = "${lookup(var.worker_instances[count.index], "min_instance_count")}:${lookup(var.worker_instances[count.index], "max_instance_count")}:${var.cluster_name}-${lookup(var.worker_instances[count.index], "instance_type")}-nodes"
    }
}

data "template_file" "autoscaler" {
    template = "${file("${path.module}/scripts/addons/autoscaler.yaml.tpl")}"

    vars {
        aws_region = "${var.aws_region}"
        asg_nodes  = "- --nodes=${join("\n            - --nodes=", null_resource.asg_node.*.triggers.asg_node)}"
    }
}

resource "aws_s3_bucket_object" "autoscaler" {
    bucket                 = "${aws_s3_bucket.scripts_bucket.bucket}"
    key                    = "addons/autoscaler.yaml"
    content                = "${data.template_file.autoscaler.rendered}"

    acl                    = "private"
    server_side_encryption = "aws:kms"
    tags                   = "${local.cluster_tags}"
}

################
# Dashboard
################

resource "aws_s3_bucket_object" "dashboard" {
    bucket                 = "${aws_s3_bucket.scripts_bucket.bucket}"
    key                    = "addons/dashboard.yaml"
    source                 = "scripts/addons/dashboard.yaml"

    acl                    = "private"
    server_side_encryption = "aws:kms"
    tags                   = "${local.cluster_tags}"
}

################
# External DNS
################

data "template_file" "external-dns" {
    template = "${file("${path.module}/scripts/addons/external-dns.yaml.tpl")}"

    vars {
        cluster_name = "${var.cluster_name}"
    }
}

resource "aws_s3_bucket_object" "external-dns" {
    bucket                 = "${aws_s3_bucket.scripts_bucket.bucket}"
    key                    = "addons/external-dns.yaml"
    content                = "${data.template_file.external-dns.rendered}"

    acl                    = "private"
    server_side_encryption = "aws:kms"
    tags                   = "${local.cluster_tags}"
}

################
# Fluentd, elastic search and kibana
################

resource "aws_s3_bucket_object" "fluentd-es-kibana-logging" {
    bucket                 = "${aws_s3_bucket.scripts_bucket.bucket}"
    key                    = "addons/fluentd-es-kibana-logging.yaml"
    source                 = "scripts/addons/fluentd-es-kibana-logging.yaml"

    acl                    = "private"
    server_side_encryption = "aws:kms"
    tags                   = "${local.cluster_tags}"
}

################
# Heapster
################

resource "aws_s3_bucket_object" "heapster" {
    bucket                 = "${aws_s3_bucket.scripts_bucket.bucket}"
    key                    = "addons/heapster.yaml"
    source                 = "scripts/addons/heapster.yaml"

    acl                    = "private"
    server_side_encryption = "aws:kms"
    tags                   = "${local.cluster_tags}"
}

################
# Ingress
################

resource "aws_s3_bucket_object" "ingress" {
    bucket                 = "${aws_s3_bucket.scripts_bucket.bucket}"
    key                    = "addons/ingress.yaml"
    source                 = "scripts/addons/ingress.yaml"

    acl                    = "private"
    server_side_encryption = "aws:kms"
    tags                   = "${local.cluster_tags}"
}

################
# Storage class
################

resource "aws_s3_bucket_object" "storage-class" {
    bucket                 = "${aws_s3_bucket.scripts_bucket.bucket}"
    key                    = "addons/storage-class.yaml"
    source                 = "scripts/addons/storage-class.yaml"

    acl                    = "private"
    server_side_encryption = "aws:kms"
    tags                   = "${local.cluster_tags}"
}

################
# Master init
################

data "template_file" "init-aws-kubernetes-master" {
    template = "${file("${path.module}/scripts/init-aws-kubernetes-master.sh.tpl")}"

    vars {
        addons          = "${join(" ", formatlist("%s/addons/%s", local.scripts_bucket_url, var.addons))}"
        aws_region      = "${var.aws_region}"
        aws_subnets     = "${join(" ", var.worker_subnet_ids)}"
        calico_yaml_url = "${local.calico_yaml_url}"
        cluster_name    = "${var.cluster_name}"
        dns_name        = "${var.cluster_name}.${var.hosted_zone}"
        kubeadm_token   = "${data.template_file.kubeadm_token.rendered}"
    }
}

resource "aws_s3_bucket_object" "init-aws-kubernetes-master" {
    bucket                 = "${aws_s3_bucket.scripts_bucket.bucket}"
    key                    = "init-aws-kubernetes-master.sh"
    content                = "${data.template_file.init-aws-kubernetes-master.rendered}"

    acl                    = "private"
    server_side_encryption = "aws:kms"
    tags                   = "${local.cluster_tags}"

    depends_on             = [
        "aws_s3_bucket_object.autoscaler",
        "aws_s3_bucket_object.dashboard",
        "aws_s3_bucket_object.external-dns",
        "aws_s3_bucket_object.fluentd-es-kibana-logging",
        "aws_s3_bucket_object.heapster",
        "aws_s3_bucket_object.ingress",
        "aws_s3_bucket_object.init-aws-kubernetes-node",
        "aws_s3_bucket_object.storage-class"
    ]
}

locals {
    init_master_url = "${local.scripts_bucket_url}/${aws_s3_bucket_object.init-aws-kubernetes-master.key}"
}