data "aws_subnet" "cluster_subnet" {
    id = "${var.master_subnet_id}"
}

#####
# Security Group - Master
#####

resource "aws_security_group" "kubernetes-master" {
    vpc_id = "${data.aws_subnet.cluster_subnet.vpc_id}"
    name   = "${var.cluster_name}-master"

    tags   = "${local.master_tags}"
}

# Allow outgoing connectivity
resource "aws_security_group_rule" "allow_all_outbound_from_kubernetes-master" {
    type              = "egress"
    from_port         = 0
    to_port           = 0
    protocol          = "-1"
    cidr_blocks       = [ "0.0.0.0/0" ]
    security_group_id = "${aws_security_group.kubernetes-master.id}"
}

# Allow SSH connections only from specific CIDR (TODO)
resource "aws_security_group_rule" "allow_ssh_from_cidr-master" {
    count             = "${length(var.ssh_access_cidr)}"
    type              = "ingress"
    from_port         = 22
    to_port           = 22
    protocol          = "tcp"
    cidr_blocks       = [ "${var.ssh_access_cidr[count.index]}" ]
    security_group_id = "${aws_security_group.kubernetes-master.id}"
}

# Allow API connections only from specific CIDR (TODO)
resource "aws_security_group_rule" "allow_api_from_cidr-master" {
    count             = "${length(var.api_access_cidr)}"
    type              = "ingress"
    from_port         = 6443
    to_port           = 6443
    protocol          = "tcp"
    cidr_blocks       = [ "${var.api_access_cidr[count.index]}" ]
    security_group_id = "${aws_security_group.kubernetes-master.id}"
}

# From master to master
resource "aws_security_group_rule" "allow_cluster_crosstalk-master2master" {
    type                     = "ingress"
    from_port                = 0
    to_port                  = 0
    protocol                 = "-1"
    source_security_group_id = "${aws_security_group.kubernetes-master.id}"
    security_group_id        = "${aws_security_group.kubernetes-master.id}"
}

#####
# Security Group - Node
#####

resource "aws_security_group" "kubernetes-node" {
    vpc_id = "${data.aws_subnet.cluster_subnet.vpc_id}"
    name   = "${var.cluster_name}-node"

    tags   = "${local.node_tags}"
}

# Allow outgoing connectivity
resource "aws_security_group_rule" "allow_all_outbound_from_kubernetes-node" {
    type              = "egress"
    from_port         = 0
    to_port           = 0
    protocol          = "-1"
    cidr_blocks       = [ "0.0.0.0/0" ]
    security_group_id = "${aws_security_group.kubernetes-node.id}"
}

# Allow SSH connections only from specific CIDR (TODO)
resource "aws_security_group_rule" "allow_ssh_from_cidr-node" {
    count             = "${length(var.ssh_access_cidr)}"
    type              = "ingress"
    from_port         = 22
    to_port           = 22
    protocol          = "tcp"
    cidr_blocks       = [ "${var.ssh_access_cidr[count.index]}" ]
    security_group_id = "${aws_security_group.kubernetes-node.id}"
}

# From node to node
resource "aws_security_group_rule" "allow_cluster_crosstalk-node2node" {
    type                     = "ingress"
    from_port                = 0
    to_port                  = 0
    protocol                 = "-1"
    source_security_group_id = "${aws_security_group.kubernetes-node.id}"
    security_group_id        = "${aws_security_group.kubernetes-node.id}"
}

##########
# Allow the security group members to talk with each other without restrictions
##########
resource "aws_security_group_rule" "allow_cluster_crosstalk-node" {
    type                     = "ingress"
    from_port                = 0
    to_port                  = 0
    protocol                 = "-1"
    source_security_group_id = "${aws_security_group.kubernetes-master.id}"
    security_group_id        = "${aws_security_group.kubernetes-node.id}"
}

resource "aws_security_group_rule" "allow_cluster_crosstalk-master" {
    type                     = "ingress"
    from_port                = 0
    to_port                  = 0
    protocol                 = "-1"
    source_security_group_id = "${aws_security_group.kubernetes-node.id}"
    security_group_id        = "${aws_security_group.kubernetes-master.id}"
}
