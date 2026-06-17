terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Secondary provider in a separate region for cross-region backup copies
provider "aws" {
  alias  = "backup_copy_region"
  region = var.backup_copy_region
}
