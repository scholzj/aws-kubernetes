resource "random_shuffle" "scripts_bucket" {
    input        = [ "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "a", "b", "c", "d", "e", "f", "g", "h", "i", "t",
        "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z" ]
    result_count = 6
}

resource "aws_s3_bucket" "scripts_bucket" {
    bucket = "${var.cluster_name}-scripts-${join("", random_shuffle.scripts_bucket.result)}"

    tags   = "${merge(map("Name", join("-", list(var.cluster_name, "master")), format("kubernetes.io/cluster/%v", var.cluster_name), "owned"), var.tags)}"
}

resource "aws_s3_bucket_object" "calico_yaml" {
    bucket = "${aws_s3_bucket.scripts_bucket.bucket}"
    key    = "calico.yaml"
    source = "scripts/calico.yaml"
    etag   = "${md5(file("scripts/calico.yaml"))}"
    acl    = "public-read"
}

resource "aws_s3_bucket_object" "init-aws-kubernetes-node" {
    bucket = "${aws_s3_bucket.scripts_bucket.bucket}"
    key    = "init-aws-kubernetes-node.sh"
    source = "scripts/init-aws-kubernetes-node.sh"
    etag   = "${md5(file("scripts/init-aws-kubernetes-node.sh"))}"
    acl    = "public-read"
}

resource "aws_s3_bucket_object" "autoscaler" {
    bucket = "${aws_s3_bucket.scripts_bucket.bucket}"
    key    = "addons/autoscaler.yaml"
    source = "scripts/addons/autoscaler.yaml"
    etag   = "${md5(file("scripts/addons/autoscaler.yaml"))}"
    acl    = "public-read"
}

resource "aws_s3_bucket_object" "dashboard" {
    bucket = "${aws_s3_bucket.scripts_bucket.bucket}"
    key    = "addons/dashboard.yaml"
    source = "scripts/addons/dashboard.yaml"
    etag   = "${md5(file("scripts/addons/dashboard.yaml"))}"
    acl    = "public-read"
}

resource "aws_s3_bucket_object" "external-dns" {
    bucket = "${aws_s3_bucket.scripts_bucket.bucket}"
    key    = "addons/external-dns.yaml"
    source = "scripts/addons/external-dns.yaml"
    etag   = "${md5(file("scripts/addons/external-dns.yaml"))}"
    acl    = "public-read"
}

resource "aws_s3_bucket_object" "fluentd-es-kibana-logging" {
    bucket = "${aws_s3_bucket.scripts_bucket.bucket}"
    key    = "addons/fluentd-es-kibana-logging.yaml"
    source = "scripts/addons/fluentd-es-kibana-logging.yaml"
    etag   = "${md5(file("scripts/addons/fluentd-es-kibana-logging.yaml"))}"
    acl    = "public-read"
}

resource "aws_s3_bucket_object" "heapster" {
    bucket = "${aws_s3_bucket.scripts_bucket.bucket}"
    key    = "addons/heapster.yaml"
    source = "scripts/addons/heapster.yaml"
    etag   = "${md5(file("scripts/addons/heapster.yaml"))}"
    acl    = "public-read"
}

resource "aws_s3_bucket_object" "ingress" {
    bucket = "${aws_s3_bucket.scripts_bucket.bucket}"
    key    = "addons/ingress.yaml"
    source = "scripts/addons/ingress.yaml"
    etag   = "${md5(file("scripts/addons/ingress.yaml"))}"
    acl    = "public-read"
}

resource "aws_s3_bucket_object" "storage-class" {
    bucket = "${aws_s3_bucket.scripts_bucket.bucket}"
    key    = "addons/storage-class.yaml"
    source = "scripts/addons/storage-class.yaml"
    etag   = "${md5(file("scripts/addons/storage-class.yaml"))}"
    acl    = "public-read"
}

resource "aws_s3_bucket_object" "init-aws-kubernetes-master" {
    bucket     = "${aws_s3_bucket.scripts_bucket.bucket}"
    key        = "init-aws-kubernetes-master.sh"
    source     = "scripts/init-aws-kubernetes-master.sh"
    etag       = "${md5(file("scripts/init-aws-kubernetes-master.sh"))}"
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