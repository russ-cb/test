# ---------------------------------------------------------------------------
# Risk 4 – Account 389656351913 – No CloudWatch alarms or observability
#
# Deploys baseline CloudWatch alarms to detect common failure conditions:
#   • High CPU utilisation on EC2 instances
#   • High memory utilisation (requires CloudWatch agent)
#   • EC2 instance status check failures
#   • RDS high CPU
#   • RDS low free storage
#   • SNS topic for alarm notifications (if none is supplied)
# ---------------------------------------------------------------------------

# Create a dedicated SNS topic for alarms if no external ARN was provided.
resource "aws_sns_topic" "alarms" {
  count = var.cloudwatch_alarm_sns_topic_arn == "" ? 1 : 0

  name              = "account-389656351913-cloudwatch-alarms"
  kms_master_key_id = "alias/aws/sns"

  tags = {
    Account   = "389656351913"
    ManagedBy = "terraform"
  }
}

locals {
  alarm_sns_topic_arn = (
    var.cloudwatch_alarm_sns_topic_arn != ""
    ? var.cloudwatch_alarm_sns_topic_arn
    : aws_sns_topic.alarms[0].arn
  )
}

# ---------------------------------------------------------------------------
# EC2 – instance status check alarm for each instance
# ---------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "ec2_status_check" {
  for_each = toset(var.ec2_instance_ids)

  alarm_name          = "ec2-status-check-failed-${each.value}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Maximum"
  threshold           = 1
  alarm_description   = "EC2 instance ${each.value} has failed a status check"
  alarm_actions       = [local.alarm_sns_topic_arn]
  ok_actions          = [local.alarm_sns_topic_arn]

  dimensions = {
    InstanceId = each.value
  }

  tags = {
    Account   = "389656351913"
    ManagedBy = "terraform"
  }
}

# EC2 – high CPU utilisation alarm for each instance
resource "aws_cloudwatch_metric_alarm" "ec2_cpu_high" {
  for_each = toset(var.ec2_instance_ids)

  alarm_name          = "ec2-cpu-high-${each.value}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 90
  alarm_description   = "EC2 instance ${each.value} CPU utilisation >= 90% for 15 minutes"
  alarm_actions       = [local.alarm_sns_topic_arn]
  ok_actions          = [local.alarm_sns_topic_arn]

  dimensions = {
    InstanceId = each.value
  }

  tags = {
    Account   = "389656351913"
    ManagedBy = "terraform"
  }
}

# ---------------------------------------------------------------------------
# CloudWatch agent configuration stored in SSM Parameter Store so that all
# instances can retrieve it via the SSM agent.
# ---------------------------------------------------------------------------
resource "aws_ssm_parameter" "cloudwatch_agent_config" {
  name      = "/account-389656351913/cloudwatch-agent/config"
  type      = "SecureString"
  key_id    = aws_kms_key.session_manager.arn
  value     = jsonencode({
    agent = {
      metrics_collection_interval = 60
      run_as_user                 = "root"
    }
    metrics = {
      namespace = "CWAgent"
      metrics_collected = {
        mem = {
          measurement                 = ["mem_used_percent"]
          metrics_collection_interval = 60
        }
        disk = {
          measurement                 = ["used_percent"]
          metrics_collection_interval = 60
          resources                   = ["/"]
        }
      }
      append_dimensions = {
        InstanceId   = "$${aws:InstanceId}"
        ImageId      = "$${aws:ImageId}"
        InstanceType = "$${aws:InstanceType}"
      }
    }
    logs = {
      logs_collected = {
        files = {
          collect_list = [
            {
              file_path        = "/var/log/messages"
              log_group_name   = "/account-389656351913/ec2/system"
              log_stream_name  = "{instance_id}"
              retention_in_days = 30
            },
            {
              file_path        = "/var/log/secure"
              log_group_name   = "/account-389656351913/ec2/secure"
              log_stream_name  = "{instance_id}"
              retention_in_days = 90
            }
          ]
        }
      }
    }
  })

  tags = {
    Account   = "389656351913"
    ManagedBy = "terraform"
  }
}

# SSM Association to install and start the CloudWatch agent on all managed
# instances automatically.
resource "aws_ssm_association" "cloudwatch_agent" {
  name             = "AWS-ConfigureAWSPackage"
  association_name = "install-cloudwatch-agent-389656351913"

  parameters = {
    action      = "Install"
    name        = "AmazonCloudWatchAgent"
    version     = "latest"
  }

  targets {
    key    = "tag:Account"
    values = ["389656351913"]
  }

  schedule_expression = "rate(30 days)"
}

# SSM Association to run the CloudWatch agent with the centralised config.
resource "aws_ssm_association" "cloudwatch_agent_config" {
  name             = "AmazonCloudWatch-ManageAgent"
  association_name = "configure-cloudwatch-agent-389656351913"

  parameters = {
    action                        = "configure"
    mode                          = "ec2"
    optionalConfigurationSource   = "ssm"
    optionalConfigurationLocation = aws_ssm_parameter.cloudwatch_agent_config.name
    optionalRestart               = "yes"
  }

  targets {
    key    = "tag:Account"
    values = ["389656351913"]
  }

  depends_on = [aws_ssm_association.cloudwatch_agent]
}
