module "kubernetes" {
  source = "scholzj/kubernetes/aws"

  aws_region           = var.aws_region
  cluster_name         = var.cluster_name
  master_instance_type = var.master_instance_type
  worker_instance_type = var.worker_instance_type
  ssh_public_key       = var.ssh_public_key
  master_subnet_id     = var.master_subnet_id
  worker_subnet_ids    = var.worker_subnet_ids
  min_worker_count     = var.min_worker_count
  max_worker_count     = var.max_worker_count
  hosted_zone          = var.hosted_zone
  hosted_zone_private  = var.hosted_zone_private
  tags                 = var.tags
  tags2                = var.tags2
  addons               = var.addons
  ssh_access_cidr      = var.ssh_access_cidr
  api_access_cidr      = var.api_access_cidr
}

