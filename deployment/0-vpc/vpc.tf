# TO RUN:
# terraform init
# terraform plan
# terraform apply --auto-approve
# terraform destroy

locals {
  arquiebrio = "jcatica"
}

terraform {
  required_version = ">= 1.8.2"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.4.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# ---------------------------
# VPC
# ---------------------------

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "vpc-mcp-arquipuntos-${local.arquiebrio}"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = true
  enable_vpn_gateway = false

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

# ---------------------------
# OUTPUTS
# ---------------------------

output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "public_subnets" {
  description = "List of public subnet IDs"
  value       = module.vpc.public_subnets
}

output "private_subnets" {
  description = "List of private subnet IDs"
  value       = module.vpc.private_subnets
}