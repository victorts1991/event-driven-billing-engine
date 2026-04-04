output "db_endpoint" {
  description = "Endereço de conexão do banco"
  value       = aws_db_instance.postgres.address
}

output "db_name" {
  description = "Nome do banco de dados inicial"
  value       = aws_db_instance.postgres.db_name
}

output "db_user" {
  value = aws_db_instance.postgres.username
}