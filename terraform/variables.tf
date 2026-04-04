variable "prefix" {
  description = "Prefixo para os nomes dos recursos"
  type        = string
  default     = "billing-engine"
}

variable "location" {
  description = "Região da AWS"
  type        = string
  default     = "us-east-2"
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