# ---------------------------------------------------------------------------
# Risk 4 – Account 389656351913 – Zero SSM coverage
#
# Enrolls EC2 instances in AWS Systems Manager by:
#   1. Ensuring the SSM agent is running via an SSM State Manager association
#   2. Configuring Session Manager preferences (logging, encryption)
#   3. Creating VPC endpoints so instances in private subnets can reach SSM
#      without an internet gateway (complements the security group hardening).
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# SSM State Manager: ensure the SSM agent is installed and running
# ---------------------------------------------------------------------------
resource "aws_ssm_association" "ssm_agent_update" {
  name             = "AWS-UpdateSSMAgent"
  association_name = "update-ssm-agent-389656351913"

  schedule_expression = "rate(14 days)"

  targets {
    key    = "tag:Account"
    values = ["389656351913"]
  }
}

# ---------------------------------------------------------------------------
# Session Manager preferences – enable session logging to CloudWatch Logs
# and S3 for auditability, and enforce KMS encryption of sessions.
# ---------------------------------------------------------------------------
resource "aws_ssm_document" "session_manager_prefs" {
  name          = "SSM-SessionManagerRunShell"
  document_type = "Session"

  content = jsonencode({
    schemaVersion = "1.0"
    description   = "Session Manager preferences for account 389656351913"
    sessionType   = "Standard_Stream"
    inputs = {
      s3BucketName                = ""
      s3KeyPrefix                 = ""
      s3EncryptionEnabled         = true
      cloudWatchLogGroupName      = "/ssm/session-manager/389656351913"
      cloudWatchEncryptionEnabled = true
      cloudWatchStreamingEnabled  = true
      idleSessionTimeout          = "20"
      maxSessionDuration          = ""
      kmsKeyId                    = aws_kms_key.session_manager.arn
      runAsEnabled                = false
      runAsDefaultUser            = ""
      shellProfile = {
        linux   = ""
        windows = ""
      }
    }
  })

  tags = {
    Account   = "389656351913"
    ManagedBy = "terraform"
  }
}

# CloudWatch log group for Session Manager session logs
resource "aws_cloudwatch_log_group" "session_manager" {
  name              = "/ssm/session-manager/389656351913"
  retention_in_days = 365
  kms_key_id        = aws_kms_key.session_manager.arn

  tags = {
    Account   = "389656351913"
    ManagedBy = "terraform"
  }
}

# KMS key for encrypting Session Manager logs and sessions
resource "aws_kms_key" "session_manager" {
  description             = "KMS key for SSM Session Manager logs – account 389656351913"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.session_manager_kms.json

  tags = {
    Account   = "389656351913"
    ManagedBy = "terraform"
  }
}

data "aws_iam_policy_document" "session_manager_kms" {
  #checkov:skip=CKV_AWS_111:Root account requires full KMS key management access per AWS best practice
  #checkov:skip=CKV_AWS_109:Root account requires KMS key management permission per AWS best practice
  #checkov:skip=CKV_AWS_356:Root account full KMS access is required for key management
  statement {
    sid    = "EnableRootAccess"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::389656351913:root"]
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }

  statement {
    sid    = "AllowSSMService"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ssm.amazonaws.com", "logs.amazonaws.com"]
    }
    actions = [
      "kms:GenerateDataKey",
      "kms:Decrypt",
      "kms:DescribeKey",
    ]
    resources = ["*"]
  }
}

resource "aws_kms_alias" "session_manager" {
  name          = "alias/account-389656351913-session-manager"
  target_key_id = aws_kms_key.session_manager.key_id
}

# ---------------------------------------------------------------------------
# VPC endpoints – allow SSM/EC2Messages/SSMMessages to reach the AWS service
# APIs from private subnets without requiring an internet gateway or NAT.
# ---------------------------------------------------------------------------
resource "aws_security_group" "ssm_endpoint" {
  name        = "account-389656351913-ssm-endpoint-sg"
  description = "HTTPS from VPC to SSM/EC2 VPC endpoints"
  vpc_id      = data.aws_vpc.main.id

  tags = {
    Account   = "389656351913"
    ManagedBy = "terraform"
  }
}

resource "aws_vpc_security_group_ingress_rule" "ssm_https_vpc" {
  security_group_id = aws_security_group.ssm_endpoint.id
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = data.aws_vpc.main.cidr_block
  description       = "HTTPS from VPC for SSM endpoints"
}

resource "aws_vpc_security_group_egress_rule" "ssm_all_out" {
  security_group_id = aws_security_group.ssm_endpoint.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
  description       = "Allow all outbound"
}

resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = data.aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.ssm"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = data.aws_subnets.private.ids
  security_group_ids  = [aws_security_group.ssm_endpoint.id]
  private_dns_enabled = true

  tags = {
    Account   = "389656351913"
    ManagedBy = "terraform"
  }
}

resource "aws_vpc_endpoint" "ssm_messages" {
  vpc_id              = data.aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = data.aws_subnets.private.ids
  security_group_ids  = [aws_security_group.ssm_endpoint.id]
  private_dns_enabled = true

  tags = {
    Account   = "389656351913"
    ManagedBy = "terraform"
  }
}

resource "aws_vpc_endpoint" "ec2_messages" {
  vpc_id              = data.aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.ec2messages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = data.aws_subnets.private.ids
  security_group_ids  = [aws_security_group.ssm_endpoint.id]
  private_dns_enabled = true

  tags = {
    Account   = "389656351913"
    ManagedBy = "terraform"
  }
}

data "aws_vpc" "main" {
  tags = {
    Account = "389656351913"
  }
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }

  tags = {
    Tier = "private"
  }
}
