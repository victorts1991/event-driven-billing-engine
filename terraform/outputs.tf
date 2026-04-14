output "sqs_url" {
  value = module.messaging.sqs_url
}

output "db_endpoint" {
  value = module.database.db_endpoint
}

output "db_name" {
  value = module.database.db_name
}

output "db_user" {
  value = module.database.db_user
  sensitive = true
}

output "redis_endpoint" {
  value = module.messaging.redis_endpoint
}

output "cluster_name" {
  value = module.cluster.cluster_name
}

output "cluster_endpoint" {
  value = module.cluster.cluster_endpoint
}

output "ecr_api_url" {
  value = module.registry.api_repository_url
}

output "ecr_worker_url" {
  value = module.registry.worker_repository_url
}