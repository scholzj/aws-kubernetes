locals {
    cluster_tags = "${merge(map(format("kubernetes.io/cluster/%v", var.cluster_name), "owned"), var.tags)}"
    master_tags  = "${merge(map("Name", format("%v-master", var.cluster_name)), local.cluster_tags)}"
    node_tags    = "${merge(map("Name", format("%v-node", var.cluster_name)), local.cluster_tags)}"
}