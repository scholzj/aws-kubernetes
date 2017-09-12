variable "aws_region" {
    description = "Region where Cloud Formation is created"
    default     = "eu-central-1"
}

variable "cluster_name" {
    description = "Name of the AWS Kubernetes cluster - will be used to name all created resources"
}

variable "tags" {
    description = "Tags used for the AWS resources created by this template"
    type        = "map"
}

variable "tags2" {
    description = "Tags in format used for the AWS Autoscaling Group"
    type        = "list"
}

variable "addons" {
    description = "list of YAML files with Kubernetes addons which should be installed"
    type        = "list"
}

variable "master_instance_type" {
    description = "Type of instance for master"
    default     = "t2.medium"
}

variable "worker_instances" {
    description = "Types of instances for workers"
    type        = "list"
    default     = [
        {
            instance_type      = "t2.medium"
            min_instance_count = 3
            max_instance_count = 6
        }
    ]
}

variable "master_subnet_id" {
    description = "The subnet-id to be used for the master instance"
}

variable "worker_subnet_ids" {
    description = "The subnet-ids to be used for the worker instances"
    type        = "list"
}

variable "ssh_public_key" {
    description = "Path to the pulic part of SSH key which should be used for the instance"
    default     = "~/.ssh/id_rsa.pub"
}

variable "hosted_zone" {
    description = "Hosted zone to be used for the alias"
}

variable "hosted_zone_private" {
    description = "Is the hosted zone public or private"
    default     = false
}

variable ssh_access_cidr {
    description = "List of CIDRs from which SSH access is allowed"
    type        = "list"
    default     = [
        "0.0.0.0/0"
    ]
}

variable api_access_cidr {
    description = "List of CIDRs from which API access is allowed"
    type        = "list"
    default     = [
        "0.0.0.0/0"
    ]
}

variable "dbg_naming_prefix" {
    description = "Prefix of the IAM role name"
    default     = "DBG-DEV-"
}