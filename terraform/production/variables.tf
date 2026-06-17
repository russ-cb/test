variable "aws_region" {
  description = "Primary AWS region for the production account"
  type        = string
  default     = "eu-west-1"
}

variable "backup_copy_region" {
  description = "Secondary AWS region used for cross-region backup copies"
  type        = string
  default     = "eu-west-2"
}

variable "vpc_cidr" {
  description = "CIDR block of the production VPC, used to restrict security group rules"
  type        = string
}

variable "admin_ip_cidrs" {
  description = "List of trusted IP CIDR blocks permitted to reach administrative ports (SSH/RDP)"
  type        = list(string)
  default     = []
}

variable "backup_cross_account_id" {
  description = "AWS account ID for cross-account backup copies (leave empty to skip)"
  type        = string
  default     = ""
}

variable "backup_vault_kms_key_arn" {
  description = "Optional KMS key ARN for encrypting the backup vault"
  type        = string
  default     = ""
}

variable "rds_kms_key_arn" {
  description = "KMS CMK ARN for RDS storage encryption and Performance Insights encryption"
  type        = string
  default     = ""
}
