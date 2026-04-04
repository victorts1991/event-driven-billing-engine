output "cluster_endpoint" {
  description = "Endpoint para o API Server do Kubernetes"
  value       = module.eks.cluster_endpoint
}

output "cluster_name" {
  description = "Nome do cluster para o comando update-kubeconfig"
  value       = module.eks.cluster_name
}

output "cluster_security_group_id" {
  value = module.eks.cluster_security_group_id
}