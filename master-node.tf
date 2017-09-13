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
aws s3 cp ${local.init_master_url} - | bash
EOF

    tags                        = "${local.master_tags}"

    root_block_device {
        volume_type           = "gp2"
        volume_size           = "50"
        delete_on_termination = true
    }

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
