# AWS region where should the AWS Kubernetes be deployed
aws_region    = "eu-central-1"

# Name for AWS resources
cluster_name  = "aws-kubernetes"

# Instance types for mster and worker nodes
master_instance_type = "t2.medium"
worker_instance_type = "t2.medium"

# SSH key for the machines
ssh_public_key = "~/.ssh/id_rsa.pub"

# Subnet ID where the cluster should run
subnet_id = "subnet-8a3517f8"

# Number of worker nodes
min_worker_count = 3
max_worker_count = 6


# DNS zone where the domain is placed
hosted_zone = "my-domain.com"
hosted_zone_private = false

# Tags
tags = {
  Application = "AWS-Kubernetes"
}

# Tags in a different format for Auto Scaling Group
tags2 = [
  {
    key                 = "Application"
    value               = "AWS-Kubernetes"
    propagate_at_launch = true
  }
]

# Kubernetes Addons
# Supported addons:
# https://s3.amazonaws.com/scholzj-kubernetes/cluster/addons/storage-class.yaml
# https://s3.amazonaws.com/scholzj-kubernetes/cluster/addons/heapster.yaml
# https://s3.amazonaws.com/scholzj-kubernetes/cluster/addons/dashboard.yaml
# https://s3.amazonaws.com/scholzj-kubernetes/cluster/addons/external-dns.yaml
# https://s3.amazonaws.com/scholzj-kubernetes/cluster/addons/ingress.yaml
# https://s3.amazonaws.com/scholzj-kubernetes/cluster/addons/autoscaler.yaml


addons = [
  "https://s3.amazonaws.com/scholzj-kubernetes/cluster/addons/storage-class.yaml",
  "https://s3.amazonaws.com/scholzj-kubernetes/cluster/addons/heapster.yaml",
  "https://s3.amazonaws.com/scholzj-kubernetes/cluster/addons/dashboard.yaml",
  "https://s3.amazonaws.com/scholzj-kubernetes/cluster/addons/external-dns.yaml",
  "https://s3.amazonaws.com/scholzj-kubernetes/cluster/addons/autoscaler.yaml"
]

# List of CIDRs from which SSH access is allowed
ssh_access_cidr = [
    "0.0.0.0/0"
]

# List of  CIDRs from which API access is allowed
api_access_cidr = [
    "0.0.0.0/0"
]