#####
# AMI image
#####

data "aws_ami" "centos7" {
    most_recent = true
    name_regex  = "^baseimage-CentOS-7-\\d{4}-\\d{2}-\\d{2}\\.*"

    filter {
        name   = "architecture"
        values = [ "x86_64" ]
    }

    filter {
        name   = "virtualization-type"
        values = [ "hvm" ]
    }
}
