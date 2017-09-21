#####
# Master - EC2 instance
#####

data "template_file" "cloud-init-config" {
    template = "${file("${path.module}/scripts/cloud-init-config.yaml.tpl")}"

    vars {
        weave_yaml_content = "${base64gzip("${file("${path.module}/scripts/weave.yaml")}")}"
    }
}

data "template_file" "init-aws-kubernetes-master" {
    template = "${file("${path.module}/scripts/init-aws-kubernetes-master.sh.tpl")}"

    vars {
        addons             = "${join(" ", var.addons)}"
        addons_zip_url     = "${local.addons_zip_url}"
        aws_region         = "${var.aws_region}"
        aws_subnets        = "${join(" ", var.worker_subnet_ids)}"
        cluster_name       = "${var.cluster_name}"
        dns_name           = "${var.cluster_name}.${var.hosted_zone}"
        kubeadm_token      = "${data.template_file.kubeadm_token.rendered}"
    }

    depends_on             = [
        "aws_s3_bucket_object.addons"
    ]
}

data "template_cloudinit_config" "cloud_init_master" {
    gzip          = true
    base64_encode = true

    part {
        filename     = "cloud-init-config.yaml"
        content_type = "text/cloud-config"
        content      = "${data.template_file.cloud-init-config.rendered}"
    }

    part {
        filename     = "init-aws-kubernetes-master.sh"
        content_type = "text/x-shellscript"
        content      = "${data.template_file.init-aws-kubernetes-master.rendered}"
    }
}

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
    user_data                   = "${data.template_cloudinit_config.cloud_init_master.rendered}"
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
