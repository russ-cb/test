# ---------------------------------------------------------------------------
# Risk 2 – Production RDS Instances Not Covered by AWS Backup
# Risk 5 – Production RDS Instance Not Configured for Multi-AZ
#
# Enables Multi-AZ on the primary production RDS instance and configures
# automated backup retention.  The AWS Backup coverage for both RDS
# instances is handled in backup.tf.
# ---------------------------------------------------------------------------

# Primary production RDS instance – enable Multi-AZ and ensure automated
# backups are configured (backup_retention_period >= 1 is required for
# point-in-time recovery and is a prerequisite for Multi-AZ).
resource "aws_db_instance" "prod_main" {
  identifier = "megger-account-management-system-production"

  # Apply changes during the next maintenance window to avoid immediate
  # downtime in production.
  apply_immediately = false

  multi_az                = true
  backup_retention_period = 30
  backup_window           = "02:00-03:00"
  maintenance_window      = "Mon:03:00-Mon:04:00"

  # Security hardening
  deletion_protection          = true
  storage_encrypted            = true
  kms_key_id                   = var.rds_kms_key_arn != "" ? var.rds_kms_key_arn : null
  auto_minor_version_upgrade   = true
  copy_tags_to_snapshot        = true
  performance_insights_enabled     = true
  performance_insights_kms_key_id  = var.rds_kms_key_arn != "" ? var.rds_kms_key_arn : null

  enabled_cloudwatch_logs_exports = ["audit", "error", "general", "slowquery"]

  monitoring_interval = 60
  monitoring_role_arn = aws_iam_role.rds_enhanced_monitoring.arn

  # All other attributes (engine, instance class, storage, VPC, credentials,
  # etc.) are managed separately or already configured.  Only the attributes
  # relevant to this remediation are specified here so that Terraform does not
  # inadvertently overwrite unrelated settings.

  lifecycle {
    # Prevent accidental destruction of the production database.
    prevent_destroy = true

    # Ignore changes to attributes that are managed outside this module (e.g.
    # passwords rotated by Secrets Manager, or engine version managed via
    # AWS-controlled patching).
    ignore_changes = [
      password,
      engine_version,
      snapshot_identifier,
    ]
  }
}

# Yield-data production RDS instance – apply the same settings as the main instance.
# Note: the identifier 'mgproductionyeilddata-prod' reflects the existing resource name
# in AWS (including the original typo). It cannot be changed without replacing the instance.
resource "aws_db_instance" "prod_yield" {
  identifier = "mgproductionyeilddata-prod"

  apply_immediately = false

  multi_az                = true
  backup_retention_period = 30
  backup_window           = "02:00-03:00"
  maintenance_window      = "Mon:03:00-Mon:04:00"

  # Security hardening
  deletion_protection          = true
  storage_encrypted            = true
  kms_key_id                   = var.rds_kms_key_arn != "" ? var.rds_kms_key_arn : null
  auto_minor_version_upgrade   = true
  copy_tags_to_snapshot        = true
  performance_insights_enabled     = true
  performance_insights_kms_key_id  = var.rds_kms_key_arn != "" ? var.rds_kms_key_arn : null

  enabled_cloudwatch_logs_exports = ["audit", "error", "general", "slowquery"]

  monitoring_interval = 60
  monitoring_role_arn = aws_iam_role.rds_enhanced_monitoring.arn

  lifecycle {
    prevent_destroy = true

    ignore_changes = [
      password,
      engine_version,
      snapshot_identifier,
    ]
  }
}

# IAM role for RDS Enhanced Monitoring
resource "aws_iam_role" "rds_enhanced_monitoring" {
  name               = "megger-prod-rds-enhanced-monitoring"
  assume_role_policy = data.aws_iam_policy_document.rds_monitoring_assume.json

  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

data "aws_iam_policy_document" "rds_monitoring_assume" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["monitoring.rds.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role_policy_attachment" "rds_enhanced_monitoring" {
  role       = aws_iam_role.rds_enhanced_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}
