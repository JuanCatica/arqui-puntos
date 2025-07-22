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

# -------------------------------------
# DynamoDB
# -------------------------------------

resource "aws_dynamodb_table" "mcp_table" {
  name           = "dynamo-mcp-arquipuntos-${local.arquiebrio}"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "architect"
  range_key      = "date"

  attribute {
    name = "architect"
    type = "S"
  }

  attribute {
    name = "date"
    type = "S"
  }
}

# The table will use also:
#   points:    N
#   note:      S
#   requester: S

# ---------------------------
# OUTPUTS
# ---------------------------

output "dynamodb_table_name" {
  description = "The name of the DynamoDB table."
  value       = aws_dynamodb_table.mcp_table.name
}

