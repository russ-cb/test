variable "aws_region" {
  description = "AWS region for account 389656351913"
  type        = string
  default     = "eu-west-1"
}

variable "backup_vault_kms_key_arn" {
  description = "Optional KMS key ARN for encrypting the backup vault"
  type        = string
  default     = ""
}

variable "ec2_instance_ids" {
  description = "List of EC2 instance IDs in this account that require IAM instance profiles and SSM enrollment"
  type        = list(string)
  default     = []
}

variable "cloudwatch_alarm_sns_topic_arn" {
  description = "SNS topic ARN for CloudWatch alarm notifications"
  type        = string
  default     = ""
}

variable "vpc_cidr" {
  description = "CIDR block of the VPC, used to restrict security group rules"
  type        = string
}
