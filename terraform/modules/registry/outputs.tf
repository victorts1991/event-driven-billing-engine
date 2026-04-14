output "api_repository_url" {
  value = aws_ecr_repository.billing_api.repository_url
}

output "worker_repository_url" {
  value = aws_ecr_repository.billing_worker.repository_url
}