#####
# Output
#####

output "minikube_dns" {
  description = "DNS hostname of the Minikube"
  value       = module.kubernetes.dns
}

output "minikube_ip" {
  description = "IP address of the Minikube"
  value       = module.kubernetes.public_ip
}

output "copy_config_dns" {
  description = "Command for copying the kubeconfig for connecting using DNS address"
  value       = "To copy the kubectl config file using DNS record, run: 'scp ${module.kubernetes.ssh_user}@${module.kubernetes.dns}:${module.kubernetes.kubeconfig_dns} .kubeconfig'"
}

output "copy_config_ip" {
  description = "Command for copying the kubeconfig for connecting using IP address"
  value       = "To copy the kubectl config file using IP address, run: 'scp ${module.kubernetes.ssh_user}@${module.kubernetes.public_ip}:${module.kubernetes.kubeconfig_ip} .kubeconfig'"
}

