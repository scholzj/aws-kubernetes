# Worker nodes array into cluster-autoscaler formated strings.
resource "null_resource" "asg_node" {
    count = "${length(var.worker_instances)}"

    triggers {
        asg_node = "${lookup(var.worker_instances[count.index], "min_instance_count")}:${lookup(var.worker_instances[count.index], "max_instance_count")}:${var.cluster_name}-${lookup(var.worker_instances[count.index], "instance_type")}-nodes"
    }
}

#####
# Master - EC2 instance
#####

resource "aws_instance" "master" {
    instance_type               = "${var.master_instance_type}"

    ami                         = "${data.aws_ami.centos7.id}"

    key_name                    = "${aws_key_pair.keypair.key_name}"

    subnet_id                   = "${var.master_subnet_id}"

    associate_public_ip_address = false

    vpc_security_group_ids      = [
        "${aws_security_group.kubernetes-master.id}"
    ]

    iam_instance_profile        = "${aws_iam_instance_profile.master_instance_profile.name}"

    user_data                   = <<EOF
#!/bin/bash
export KUBEADM_TOKEN=${data.template_file.kubeadm_token.rendered}
export DNS_NAME=${var.cluster_name}.${var.hosted_zone}
export CLUSTER_NAME=${var.cluster_name}
export ASG_NODES="- --nodes=${join(" --nodes=", null_resource.asg_node.*.triggers.asg_node)}"
export AWS_REGION=${var.aws_region}
export AWS_SUBNETS="${join(" ", var.worker_subnet_ids)}"
export ADDONS="${join(" ", formatlist("https://%s/addons/%s", aws_s3_bucket.scripts_bucket.bucket_domain_name, var.addons))}"
export CALICO_YAML_URL="https://${aws_s3_bucket.scripts_bucket.bucket_domain_name}/${aws_s3_bucket_object.calico_yaml.key}"

curl -L https://${aws_s3_bucket.scripts_bucket.bucket_domain_name}/${aws_s3_bucket_object.init-aws-kubernetes-master.key} | bash
EOF

    tags                        = "${merge(map("Name", join("-", list(var.cluster_name, "master")), format("kubernetes.io/cluster/%v", var.cluster_name), "owned"), var.tags)}"

    root_block_device {
        volume_type           = "gp2"
        volume_size           = "50"
        delete_on_termination = true
    }

    depends_on                  = [
        "data.template_file.kubeadm_token",
        "aws_s3_bucket_object.init-aws-kubernetes-master",
        "aws_s3_bucket_object.calico_yaml"
    ]

    lifecycle {
        ignore_changes = [
            "ami",
            "user_data",
            "associate_public_ip_address"
        ]
    }
}

#####
# DNS record
#####

data "aws_route53_zone" "dns_zone" {
    name         = "${var.hosted_zone}."
    private_zone = "${var.hosted_zone_private}"
}

resource "aws_route53_record" "master" {
    zone_id = "${data.aws_route53_zone.dns_zone.zone_id}"
    name    = "${var.cluster_name}.${var.hosted_zone}"
    type    = "A"
    records = [ "${aws_instance.master.private_ip}" ]
    ttl     = 300
}

#####
# Output
#####

output "master_dns" {
    value = "${aws_route53_record.master.fqdn}"
}

output "copy_config" {
    value = "To copy the kubectl config file, run: 'scp -i ${replace(var.ssh_public_key, ".pub", "")} centos@${aws_route53_record.master.fqdn}:/home/centos/kubeconfig .'"
}
