variable "prefix" {
  type = string
}

variable "location" {
  type = string
}

variable "db_username" {
  description = "Usuário administrativo do RDS"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Senha administrativa do RDS"
  type        = string
  sensitive   = true
}