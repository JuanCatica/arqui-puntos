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
# ECR Repository
# ---------------------------

resource "aws_ecr_repository" "mcp_server_repo" {
  name = "ecr-mcp-arquipuntos-${local.arquiebrio}"
}

# ---------------------------
# OUTPUTS
# ---------------------------

output "ecr_repository_url" {
  value = aws_ecr_repository.mcp_server_repo.repository_url
}
