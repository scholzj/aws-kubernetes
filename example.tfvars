# AWS region where should the AWS Kubernetes be deployed
aws_region    = "eu-central-1"

# Name for AWS resources
cluster_name  = "aws-kubernetes"

# Instance types for mster and worker nodes
master_instance_type = "t2.medium"
worker_instance_type = "t2.medium"

# SSH key for the machines
ssh_public_key = "~/.ssh/id_rsa.pub"

# Subnet IDs where the cluster should run (should belong to the same VPC)
# - Master can be only in single subnet
# - Workers can be in multiple subnets
# - Worker subnets can contain also the master subnet
master_subnet_id = "subnet-8a3517f8"
worker_subnet_ids = [		
    "subnet-8a3517f8",
    "subnet-9b7853f7",
    "subnet-8g9sdfv8"
]

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
# https://raw.githubusercontent.com/scholzj/terraform-aws-kubernetes/master/addons/storage-class.yaml
# https://raw.githubusercontent.com/scholzj/terraform-aws-kubernetes/master/addons/heapster.yaml
# https://raw.githubusercontent.com/scholzj/terraform-aws-kubernetes/master/addons/dashboard.yaml
# https://raw.githubusercontent.com/scholzj/terraform-aws-kubernetes/master/addons/external-dns.yaml
# https://raw.githubusercontent.com/scholzj/terraform-aws-kubernetes/master/addons/autoscaler.yaml
# https://raw.githubusercontent.com/scholzj/terraform-aws-kubernetes/master/addons/ingress.yaml
# https://raw.githubusercontent.com/scholzj/terraform-aws-kubernetes/master/addons/fluentd-es-kibana-logging.yaml

addons = [
  "https://raw.githubusercontent.com/scholzj/terraform-aws-kubernetes/master/addons/storage-class.yaml",
  "https://raw.githubusercontent.com/scholzj/terraform-aws-kubernetes/master/addons/metrics-server.yaml",
  "https://raw.githubusercontent.com/scholzj/terraform-aws-kubernetes/master/addons/dashboard.yaml",
  "https://raw.githubusercontent.com/scholzj/terraform-aws-kubernetes/master/addons/external-dns.yaml",
  "https://raw.githubusercontent.com/scholzj/terraform-aws-kubernetes/master/addons/autoscaler.yaml"
]

# List of CIDRs from which SSH access is allowed
ssh_access_cidr = [
    "0.0.0.0/0"
]

# List of  CIDRs from which API access is allowed
api_access_cidr = [
    "0.0.0.0/0"
]
