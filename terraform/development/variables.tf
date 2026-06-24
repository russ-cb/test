variable "aws_region" {
  description = "Primary AWS region for the development account"
  type        = string
  default     = "eu-west-1"
}

variable "backup_vault_kms_key_arn" {
  description = "Optional KMS key ARN for encrypting the backup vault"
  type        = string
  default     = ""
}

variable "vpc_cidr" {
  description = "CIDR block of the development VPC, used to restrict security group rules"
  type        = string
}

variable "admin_ip_cidrs" {
  description = "List of trusted IP CIDR blocks permitted to reach administrative ports"
  type        = list(string)
  default     = []
}
