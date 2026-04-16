variable "prefix" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "admin_principal_arn" {
  description = "ARN do usuário admin capturado na raiz"
  type        = string
}