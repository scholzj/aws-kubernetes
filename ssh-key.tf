##########
# Keypair
##########

resource "aws_key_pair" "keypair" {
    key_name   = "${var.cluster_name}"
    public_key = "${file(var.ssh_public_key)}"
}
