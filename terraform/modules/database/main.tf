# --- Security Group: O Firewall do Banco ---
resource "aws_security_group" "db_sg" {
  name        = "${var.prefix}-db-sg"
  description = "Permitir acesso ao Postgres vindo do EKS"
  # vpc_id = var.vpc_id # Se voce tiver o modulo de network pronto, descomente aqui

  ingress {
    description = "Postgres Port"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Em prod, restringimos ao CIDR da VPC
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- RDS: Postgres Instance ---
resource "aws_db_instance" "postgres" {
  identifier           = "${var.prefix}-db"
  engine               = "postgres"
  engine_version       = "15"
  instance_class       = "db.t3.micro"
  allocated_storage     = 20
  max_allocated_storage = 50
  
  db_name              = "billingdb"
  
  # Usando as variáveis
  username             = var.db_username
  password             = var.db_password
  
  parameter_group_name = "default.postgres15"
  skip_final_snapshot  = true
  publicly_accessible  = true
  
  vpc_security_group_ids = [aws_security_group.db_sg.id]

  tags = {
    Name = "${var.prefix}-postgresql"
  }
}