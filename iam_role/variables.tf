variable "aws_region" {
    description = "Region where Cloud Formation is created"
    default     = "eu-central-1"
}

variable "cluster_name" {
    description = "Name of the AWS Minikube cluster - will be used to name all created resources"
}

variable "tags" {
    description = "Tags used for the AWS resources created by this template"
    type        = "map"
}

variable "dbg_naming_prefix" {
    description = "Mandatory DBG naming prefix for IAM roles"
    default     = "DBG-DEV-"
}

variable "template_url" {
    description = "DBG Role template URL for the cloud formation stack"
    default     = "https://s3.eu-central-1.amazonaws.com/init-prod-dev-s3bucket-15205kjmp3ix0/RoleGeneration/DBG-CORE-ROLE-Trigger.template"
}
