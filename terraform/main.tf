terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket = "stbilling-enginetfb8dc1b"
    key    = "billing-engine.tfstate"
    region = "us-east-2"
  }
}

provider "aws" {
  region = var.location
}

# --- Identidade ---
data "aws_caller_identity" "current" {}

# --- 0. Network (VPC Default da AWS para simplificar como no Azure) ---
data "aws_vpc" "default" { default = true }
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# --- 1. Mensageria (SQS + Redis) ---
module "messaging" {
  source   = "./modules/messaging"
  prefix   = var.prefix
  location = var.location
  vpc_id   = data.aws_vpc.default.id
}

# --- 2. Database (RDS Postgres) ---
module "database" {
  source      = "./modules/database"
  prefix      = var.prefix
  location    = var.location
  db_username = var.db_username # Vem de TF_VAR_db_username
  db_password = var.db_password # Vem de TF_VAR_db_password
}

# --- 3. Cluster (EKS) ---
module "cluster" {
  source     = "./modules/cluster"
  prefix     = var.prefix
  vpc_id     = data.aws_vpc.default.id
  subnet_ids = data.aws_subnets.default.ids

}

# --- 4. Container Registry (ECR) ---
module "registry" {
  source = "./modules/registry"
  prefix = var.prefix
}