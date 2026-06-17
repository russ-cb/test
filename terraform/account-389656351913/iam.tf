# ---------------------------------------------------------------------------
# Risk 4 – Account 389656351913 – EC2 instances running without IAM instance
# profiles, preventing SSM connectivity and limiting observability.
#
# Creates a shared IAM instance profile that grants EC2 instances the
# minimum permissions required for:
#   • SSM Session Manager (replaces need for open SSH port)
#   • CloudWatch agent metric/log publishing
#   • S3 read access to retrieve the CloudWatch agent config (optional)
# ---------------------------------------------------------------------------

resource "aws_iam_role" "ec2_instance" {
  name               = "account-389656351913-ec2-instance-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json

  tags = {
    Account   = "389656351913"
    ManagedBy = "terraform"
  }
}

data "aws_iam_policy_document" "ec2_assume" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

# SSM managed instance core – required for Session Manager
resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ec2_instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# CloudWatch agent – allows the agent to publish metrics and logs
resource "aws_iam_role_policy_attachment" "cloudwatch_agent" {
  role       = aws_iam_role.ec2_instance.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Instance profile that associates the role with EC2 instances
resource "aws_iam_instance_profile" "ec2_instance" {
  name = "account-389656351913-ec2-instance-profile"
  role = aws_iam_role.ec2_instance.name

  tags = {
    Account   = "389656351913"
    ManagedBy = "terraform"
  }
}

# ---------------------------------------------------------------------------
# Associate the instance profile with each existing EC2 instance.
# The list of instance IDs is supplied via var.ec2_instance_ids.
# ---------------------------------------------------------------------------
resource "aws_iam_instance_profile_association" "ec2" {
  for_each = toset(var.ec2_instance_ids)

  instance_id = each.value
  iam_arn     = aws_iam_instance_profile.ec2_instance.arn
}
