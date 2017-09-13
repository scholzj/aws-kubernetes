#####
# Nodes
#####

resource "aws_launch_configuration" "nodes" {
    count                       = "${length(var.worker_instances)}"
    name                        = "${var.cluster_name}-${lookup(var.worker_instances[count.index], "instance_type")}-nodes"
    image_id                    = "${data.aws_ami.centos7.id}"
    instance_type               = "${lookup(var.worker_instances[count.index], "instance_type")}"
    key_name                    = "${aws_key_pair.keypair.key_name}"
    iam_instance_profile        = "${aws_iam_instance_profile.node_instance_profile.name}"

    security_groups             = [
        "${aws_security_group.kubernetes-node.id}"
    ]

    associate_public_ip_address = false

    user_data                   = <<EOF
#!/bin/bash
aws s3 cp ${local.init_node_url} - | bash
EOF

    root_block_device {
        volume_type           = "gp2"
        volume_size           = "50"
        delete_on_termination = true
    }

    lifecycle {
        create_before_destroy = true
        ignore_changes        = [
            "user_data"
        ]
    }
}

resource "aws_autoscaling_group" "nodes" {
    vpc_zone_identifier  = "${var.worker_subnet_ids}"

    count                = "${length(var.worker_instances)}"
    name                 = "${var.cluster_name}-${lookup(var.worker_instances[count.index], "instance_type")}-nodes"
    max_size             = "${lookup(var.worker_instances[count.index], "max_instance_count")}"
    min_size             = "${lookup(var.worker_instances[count.index], "min_instance_count")}"
    desired_capacity     = "${lookup(var.worker_instances[count.index], "min_instance_count")}"
    launch_configuration = "${var.cluster_name}-${lookup(var.worker_instances[count.index], "instance_type")}-nodes"

    depends_on           = [ "aws_launch_configuration.nodes" ]

    tags                 = [ {
        key                 = "Name"
        value               = "${var.cluster_name}-node"
        propagate_at_launch = true
    } ]

    tags                 = [ {
        key                 = "kubernetes.io/cluster/${var.cluster_name}"
        value               = "owned"
        propagate_at_launch = true
    } ]

    tags                 = [ "${var.tags2}" ]
}