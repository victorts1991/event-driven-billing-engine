# --- SQS: Fila de Mortos (Dead Letter Queue) ---
resource "aws_sqs_queue" "billing_dlq" {
  name = "${var.prefix}-invoice-dlq"
  
  # Retenção de 14 dias para análise manual de falhas de cobrança
  message_retention_seconds = 1209600 
}

# --- SQS: Fila Principal de Processamento ---
resource "aws_sqs_queue" "billing_queue" {
  name                      = "${var.prefix}-invoice-queue"
  delay_seconds             = 0
  message_retention_seconds = 86400 # 1 dia
  receive_wait_time_seconds = 10    # Long Polling

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.billing_dlq.arn
    maxReceiveCount     = 3 # Tenta 3 vezes antes de mandar para a DLQ
  })
}

# --- Redis (ElastiCache) para Idempotência ---
# Nota: O Redis na AWS precisa de um Subnet Group e Security Group
resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "${var.prefix}-redis"
  engine               = "redis"
  node_type            = "cache.t3.micro" # Econômico para dev/portfolio
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"
  port                 = 6379
  
  # Aplica as tags para organização
  tags = {
    Name = "${var.prefix}-idempotency-cache"
  }
}