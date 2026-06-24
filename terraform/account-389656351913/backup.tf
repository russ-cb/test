# ---------------------------------------------------------------------------
# Risk 4 – Account 389656351913 Has No Backup Coverage Whatsoever
#
# Creates a comprehensive AWS Backup plan covering all supported resource
# types in this account using tag-based selection.
# ---------------------------------------------------------------------------

resource "aws_backup_vault" "main" {
  name        = "account-389656351913-backup-vault"
  kms_key_arn = var.backup_vault_kms_key_arn != "" ? var.backup_vault_kms_key_arn : null

  tags = {
    Account   = "389656351913"
    ManagedBy = "terraform"
  }
}

resource "aws_iam_role" "backup" {
  name               = "account-389656351913-backup-role"
  assume_role_policy = data.aws_iam_policy_document.backup_assume.json

  tags = {
    Account   = "389656351913"
    ManagedBy = "terraform"
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

# Backup plan with two rules:
#   1. Daily backups retained for 30 days
#   2. Weekly backups retained for 90 days (longer window for point-in-time recovery)
resource "aws_backup_plan" "main" {
  name = "account-389656351913-daily-backup"

  rule {
    rule_name         = "daily-30-day-retention"
    target_vault_name = aws_backup_vault.main.name
    schedule          = "cron(0 5 * * ? *)"

    start_window      = 60
    completion_window = 180

    lifecycle {
      delete_after = 30
    }
  }

  rule {
    rule_name         = "weekly-90-day-retention"
    target_vault_name = aws_backup_vault.main.name
    schedule          = "cron(0 5 ? * 1 *)" # Every Sunday at 05:00 UTC

    start_window      = 60
    completion_window = 180

    lifecycle {
      delete_after = 90
    }
  }

  tags = {
    Account   = "389656351913"
    ManagedBy = "terraform"
  }
}

# Assign all resources tagged with Backup=true (apply this tag to all
# resources that should be backed up).
resource "aws_backup_selection" "all_tagged" {
  name         = "account-389656351913-all-selection"
  iam_role_arn = aws_iam_role.backup.arn
  plan_id      = aws_backup_plan.main.id

  selection_tag {
    type  = "STRINGEQUALS"
    key   = "Backup"
    value = "true"
  }
}
