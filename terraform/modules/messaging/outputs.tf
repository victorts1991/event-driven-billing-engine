output "sqs_url" {
  description = "URL da fila principal para o Producer (NestJS)"
  value       = aws_sqs_queue.billing_queue.id
}

output "sqs_arn" {
  description = "ARN da fila para permissões de IAM"
  value       = aws_sqs_queue.billing_queue.arn
}

output "redis_endpoint" {
  description = "Endereço do Redis para a lógica de idempotência"
  value       = aws_elasticache_cluster.redis.cache_nodes[0].address
}