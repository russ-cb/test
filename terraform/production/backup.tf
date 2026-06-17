# ---------------------------------------------------------------------------
# Risk 2 – Production RDS Instances Not Covered by AWS Backup
#
# Creates an AWS Backup plan that runs daily, retains backups for 30 days,
# and copies each recovery point to a second region (and optionally a second
# account) for disaster-recovery purposes.
# ---------------------------------------------------------------------------

# Backup vault in the primary region
resource "aws_backup_vault" "prod" {
  name        = "megger-prod-backup-vault"
  kms_key_arn = var.backup_vault_kms_key_arn != "" ? var.backup_vault_kms_key_arn : null

  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

# Backup vault in the copy (DR) region
resource "aws_backup_vault" "prod_copy" {
  provider = aws.backup_copy_region

  name        = "megger-prod-backup-vault-dr"
  kms_key_arn = var.backup_vault_kms_key_arn != "" ? var.backup_vault_kms_key_arn : null

  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

# IAM role assumed by AWS Backup
resource "aws_iam_role" "backup" {
  name               = "megger-prod-backup-role"
  assume_role_policy = data.aws_iam_policy_document.backup_assume.json

  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

data "aws_iam_policy_document" "backup_assume" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["backup.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role_policy_attachment" "backup_default" {
  role       = aws_iam_role.backup.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

resource "aws_iam_role_policy_attachment" "backup_restore" {
  role       = aws_iam_role.backup.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores"
}

# ---------------------------------------------------------------------------
# Backup plan – daily backup, 30-day retention, cross-region DR copy
# ---------------------------------------------------------------------------
resource "aws_backup_plan" "prod_rds" {
  name = "megger-prod-rds-daily-backup"

  rule {
    rule_name         = "daily-backup"
    target_vault_name = aws_backup_vault.prod.name
    schedule          = "cron(0 3 * * ? *)" # 03:00 UTC daily

    start_window      = 60   # minutes after schedule to start
    completion_window = 180  # minutes after start to complete

    lifecycle {
      delete_after = 30 # days
    }

    copy_action {
      destination_vault_arn = aws_backup_vault.prod_copy.arn

      lifecycle {
        delete_after = 30
      }
    }
  }

  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

# ---------------------------------------------------------------------------
# Assign both production RDS instances to the backup plan
# ---------------------------------------------------------------------------
resource "aws_backup_selection" "prod_rds" {
  name         = "megger-prod-rds-selection"
  iam_role_arn = aws_iam_role.backup.arn
  plan_id      = aws_backup_plan.prod_rds.id

  resources = [
    aws_db_instance.prod_main.arn,
    aws_db_instance.prod_yield.arn,
  ]
}
