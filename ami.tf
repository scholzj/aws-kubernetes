#####
# AMI image
#####

data "aws_ami" "centos7" {
    most_recent = true

    filter {
        name   = "product-code"
        values = ["aw0evgkw8e5c1q413zgy5pjce"]
    }

    filter {
        name   = "architecture"
        values = [ "x86_64" ]
    }

    filter {
        name   = "virtualization-type"
        values = [ "hvm" ]
    }
}
