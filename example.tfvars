# AWS region where should the AWS Kubernetes be deployed
aws_region           = "eu-central-1"

# Name for AWS resources
cluster_name         = "aws-kubernetes"

# Instance types for master and worker nodes
master_instance_type = "t2.medium"
worker_instances     = [
    {
        instance_type      = "t2.medium"
        min_instance_count = 3
        max_instance_count = 6
    }
]

# SSH key for the machines
ssh_public_key       = "~/.ssh/id_rsa.pub"

# Subnet IDs where the cluster should run (should belong to the same VPC)
# - Master can be only in single subnet
# - Workers can be in multiple subnets
# - Worker subnets can contain also the master subnet
# - If you want to run workers in different subnet(s) than master you have to tag the subnets with kubernetes.io/cluster/{cluster_name}=shared
master_subnet_id     = "subnet-ca9dcca2"
worker_subnet_ids    = [
    "subnet-ca9dcca2",
    "subnet-a4a639de",
    "subnet-081e1b42"
]

# DNS zone where the domain is placed
hosted_zone          = "my-domain.com"
hosted_zone_private  = false

# Tags
tags                 = {
    Product     = "Risk"
    CostCenter  = "665050"
    Creator     = "<user-name>"
    Owner       = "<user-name>"
    Application = "AWS-Kubernetes"
}

# Tags in a different format for Auto Scaling Group
tags2                = [
    {
        key                 = "Owner"
        value               = "<user-name>"
        propagate_at_launch = true
    },
    {
        key                 = "Product"
        value               = "Risk"
        propagate_at_launch = true
    },
    {
        key                 = "CostCenter"
        value               = "665050"
        propagate_at_launch = true
    },
    {
        key                 = "Creator"
        value               = "<user-name>"
        propagate_at_launch = true
    },
    {
        key                 = "Application"
        value               = "AWS-Kubernetes"
        propagate_at_launch = true
    }
]

# Kubernetes Addons
# Supported addons:
#     heapster
#     storage-class
#     external-dns
#     nginx-ingress
#     cluster-autoscaler
#     kubernetes-dashboard
#     logging


addons               = [
    "heapster",
    "storage-class",
    "external-dns",
    "cluster-autoscaler",
    "kubernetes-dashboard"
]

# List of CIDRs from which SSH access is allowed
ssh_access_cidr      = [
    "0.0.0.0/0"
]

# List of  CIDRs from which API access is allowed
api_access_cidr      = [
    "0.0.0.0/0"
]