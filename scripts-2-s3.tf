resource "random_shuffle" "scripts_bucket" {
    input        = [ "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "a", "b", "c", "d", "e", "f", "g", "h", "i", "t",
        "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z" ]
    result_count = 6
}

resource "aws_s3_bucket" "scripts_bucket" {
    bucket = "${var.cluster_name}-scripts-${join("", random_shuffle.scripts_bucket.result)}"

    tags   = "${merge(map("Name", join("-", list(var.cluster_name, "master")), format("kubernetes.io/cluster/%v", var.cluster_name), "owned"), var.tags)}"
}

################
# Calico
################

resource "aws_s3_bucket_object" "calico_yaml" {
    bucket = "${aws_s3_bucket.scripts_bucket.bucket}"
    key    = "calico.yaml"
    source = "scripts/calico.yaml"
    etag   = "${md5(file("scripts/calico.yaml"))}"
    acl    = "public-read"
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
    bucket  = "${aws_s3_bucket.scripts_bucket.bucket}"
    key     = "init-aws-kubernetes-node.sh"
    content = "${data.template_file.init-aws-kubernetes-node.rendered}"
    etag    = "${md5(data.template_file.init-aws-kubernetes-node.rendered)}"
    acl     = "public-read"
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
    bucket  = "${aws_s3_bucket.scripts_bucket.bucket}"
    key     = "addons/autoscaler.yaml"
    content = "${data.template_file.autoscaler.rendered}"
    etag    = "${md5(data.template_file.autoscaler.rendered)}"
    acl     = "public-read"
}

################
# Dashboard
################

resource "aws_s3_bucket_object" "dashboard" {
    bucket = "${aws_s3_bucket.scripts_bucket.bucket}"
    key    = "addons/dashboard.yaml"
    source = "scripts/addons/dashboard.yaml"
    etag   = "${md5(file("scripts/addons/dashboard.yaml"))}"
    acl    = "public-read"
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
    bucket  = "${aws_s3_bucket.scripts_bucket.bucket}"
    key     = "addons/external-dns.yaml"
    content = "${data.template_file.external-dns.rendered}"
    etag    = "${md5(data.template_file.external-dns.rendered)}"
    acl     = "public-read"
}

################
# Fluentd, elastic search and kibana
################

resource "aws_s3_bucket_object" "fluentd-es-kibana-logging" {
    bucket = "${aws_s3_bucket.scripts_bucket.bucket}"
    key    = "addons/fluentd-es-kibana-logging.yaml"
    source = "scripts/addons/fluentd-es-kibana-logging.yaml"
    etag   = "${md5(file("scripts/addons/fluentd-es-kibana-logging.yaml"))}"
    acl    = "public-read"
}

################
# Heapster
################

resource "aws_s3_bucket_object" "heapster" {
    bucket = "${aws_s3_bucket.scripts_bucket.bucket}"
    key    = "addons/heapster.yaml"
    source = "scripts/addons/heapster.yaml"
    etag   = "${md5(file("scripts/addons/heapster.yaml"))}"
    acl    = "public-read"
}

################
# Ingress
################

resource "aws_s3_bucket_object" "ingress" {
    bucket = "${aws_s3_bucket.scripts_bucket.bucket}"
    key    = "addons/ingress.yaml"
    source = "scripts/addons/ingress.yaml"
    etag   = "${md5(file("scripts/addons/ingress.yaml"))}"
    acl    = "public-read"
}

################
# Storage class
################

resource "aws_s3_bucket_object" "storage-class" {
    bucket = "${aws_s3_bucket.scripts_bucket.bucket}"
    key    = "addons/storage-class.yaml"
    source = "scripts/addons/storage-class.yaml"
    etag   = "${md5(file("scripts/addons/storage-class.yaml"))}"
    acl    = "public-read"
}

################
# Master init
################

data "template_file" "init-aws-kubernetes-master" {
    template = "${file("${path.module}/scripts/init-aws-kubernetes-master.sh.tpl")}"

    vars {
        addons          = "${join(" ", formatlist("https://%s/addons/%s", aws_s3_bucket.scripts_bucket.bucket_domain_name, var.addons))}"
        aws_region      = "${var.aws_region}"
        aws_subnets     = "${join(" ", var.worker_subnet_ids)}"
        calico_yaml_url = "https://${aws_s3_bucket.scripts_bucket.bucket_domain_name}/${aws_s3_bucket_object.calico_yaml.key}"
        cluster_name    = "${var.cluster_name}"
        dns_name        = "${var.cluster_name}.${var.hosted_zone}"
        kubeadm_token   = "${data.template_file.kubeadm_token.rendered}"
    }
}

resource "aws_s3_bucket_object" "init-aws-kubernetes-master" {
    bucket     = "${aws_s3_bucket.scripts_bucket.bucket}"
    key        = "init-aws-kubernetes-master.sh"
    content    = "${data.template_file.init-aws-kubernetes-master.rendered}"
    etag       = "${md5(data.template_file.init-aws-kubernetes-master.rendered)}"
    acl        = "public-read"
    depends_on = [
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