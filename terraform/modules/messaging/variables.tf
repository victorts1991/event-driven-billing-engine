variable "prefix" {}

variable "location" {}

variable "vpc_id" {
  type        = string
  description = "ID da VPC onde o Redis será implantado"
}
