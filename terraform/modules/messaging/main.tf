# --- 1. SQS: Fila de Mortos ---
resource "aws_sqs_queue" "billing_dlq" {
  name                      = "${var.prefix}-invoice-dlq"
  message_retention_seconds = 1209600 
}

# --- 2. SQS: Fila Principal ---
resource "aws_sqs_queue" "billing_queue" {
  name                      = "${var.prefix}-invoice-queue"
  delay_seconds             = 0
  message_retention_seconds = 86400
  receive_wait_time_seconds = 10 

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.billing_dlq.arn
    maxReceiveCount     = 3
  })
}

# --- 3. Infra de Rede para o Redis ---
data "aws_subnets" "all" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
}

resource "aws_elasticache_subnet_group" "redis_subnets" {
  name       = "${var.prefix}-redis-subnets"
  subnet_ids = data.aws_subnets.all.ids
}

resource "aws_security_group" "redis_sg" {
  name        = "${var.prefix}-redis-sg"
  description = "Allow Redis traffic from EKS"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- 4. Cluster Redis ---
resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "${var.prefix}-redis"
  engine               = "redis"
  node_type            = "cache.t3.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"
  port                 = 6379
  
  subnet_group_name    = aws_elasticache_subnet_group.redis_subnets.name
  security_group_ids   = [aws_security_group.redis_sg.id]

  tags = {
    Name = "${var.prefix}-idempotency-cache"
  }
}