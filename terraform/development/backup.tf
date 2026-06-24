# ---------------------------------------------------------------------------
# Risk 2 – Development RDS Instance Not Covered by AWS Backup
#
# Creates an AWS Backup plan for the development RDS instance with a daily
# schedule and 14-day retention (shorter than production given the lower
# criticality, but still providing a meaningful recovery window).
# ---------------------------------------------------------------------------

resource "aws_backup_vault" "dev" {
  name        = "megger-dev-backup-vault"
  kms_key_arn = var.backup_vault_kms_key_arn != "" ? var.backup_vault_kms_key_arn : null

  tags = {
    Environment = "development"
    ManagedBy   = "terraform"
  }
}

resource "aws_iam_role" "backup" {
  name               = "megger-dev-backup-role"
  assume_role_policy = data.aws_iam_policy_document.backup_assume.json

  tags = {
    Environment = "development"
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

resource "aws_backup_plan" "dev_rds" {
  name = "megger-dev-rds-daily-backup"

  rule {
    rule_name         = "daily-backup"
    target_vault_name = aws_backup_vault.dev.name
    schedule          = "cron(0 4 * * ? *)" # 04:00 UTC daily

    start_window      = 60
    completion_window = 180

    lifecycle {
      delete_after = 14
    }
  }

  tags = {
    Environment = "development"
    ManagedBy   = "terraform"
  }
}

resource "aws_backup_selection" "dev_rds" {
  name         = "megger-dev-rds-selection"
  iam_role_arn = aws_iam_role.backup.arn
  plan_id      = aws_backup_plan.dev_rds.id

  # Tag-based selection: any RDS instance tagged Environment=development is
  # automatically included, so new instances are covered without code changes.
  selection_tag {
    type  = "STRINGEQUALS"
    key   = "Environment"
    value = "development"
  }
}
