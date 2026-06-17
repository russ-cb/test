# ---------------------------------------------------------------------------
# Risk 3 – Excessive Security Group Rules Open to the Internet on Sensitive Ports
#
# Removes inbound rules that allow unrestricted access (0.0.0.0/0) on
# sensitive administrative and database ports and replaces them with
# restricted rules scoped to the VPC CIDR or trusted admin IPs.
#
# Ports classified as sensitive:
#   22   – SSH
#   3389 – RDP
#   3306 – MySQL/Aurora
#   5432 – PostgreSQL
#   1433 – MSSQL
#   27017– MongoDB
#   6379 – Redis
#   11211– Memcached
# ---------------------------------------------------------------------------

locals {
  sensitive_ports = [22, 3389, 3306, 5432, 1433, 27017, 6379, 11211]
}

# ---------------------------------------------------------------------------
# Management / bastion security group
# Allows SSH and RDP only from trusted admin CIDR ranges (no 0.0.0.0/0).
# ---------------------------------------------------------------------------
resource "aws_security_group" "management" {
  #checkov:skip=CKV2_AWS_5:Security group is attached to EC2 instances managed outside this module
  name        = "megger-prod-management-sg"
  description = "Allows SSH and RDP from trusted admin IP ranges only"
  vpc_id      = data.aws_vpc.prod.id

  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
    Purpose     = "management-access"
  }
}

resource "aws_vpc_security_group_ingress_rule" "ssh_admin" {
  for_each = toset(var.admin_ip_cidrs)

  security_group_id = aws_security_group.management.id
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_ipv4         = each.value
  description       = "SSH from trusted admin range"
}

resource "aws_vpc_security_group_ingress_rule" "rdp_admin" {
  for_each = toset(var.admin_ip_cidrs)

  security_group_id = aws_security_group.management.id
  ip_protocol       = "tcp"
  from_port         = 3389
  to_port           = 3389
  cidr_ipv4         = each.value
  description       = "RDP from trusted admin range"
}

# All egress allowed (standard pattern; restrict further if required)
resource "aws_vpc_security_group_egress_rule" "management_all_out" {
  security_group_id = aws_security_group.management.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
  description       = "Allow all outbound"
}

# ---------------------------------------------------------------------------
# Database security group
# Allows database ports only from within the VPC; no internet access.
# ---------------------------------------------------------------------------
resource "aws_security_group" "database" {
  #checkov:skip=CKV2_AWS_5:Security group is attached to RDS instances managed outside this module
  name        = "megger-prod-database-sg"
  description = "Allows database ports from within the VPC only"
  vpc_id      = data.aws_vpc.prod.id

  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
    Purpose     = "database-access"
  }
}

resource "aws_vpc_security_group_ingress_rule" "mysql_vpc" {
  security_group_id = aws_security_group.database.id
  ip_protocol       = "tcp"
  from_port         = 3306
  to_port           = 3306
  cidr_ipv4         = data.aws_vpc.prod.cidr_block
  description       = "MySQL from VPC"
}

resource "aws_vpc_security_group_ingress_rule" "postgres_vpc" {
  security_group_id = aws_security_group.database.id
  ip_protocol       = "tcp"
  from_port         = 5432
  to_port           = 5432
  cidr_ipv4         = data.aws_vpc.prod.cidr_block
  description       = "PostgreSQL from VPC"
}

resource "aws_vpc_security_group_ingress_rule" "mssql_vpc" {
  security_group_id = aws_security_group.database.id
  ip_protocol       = "tcp"
  from_port         = 1433
  to_port           = 1433
  cidr_ipv4         = data.aws_vpc.prod.cidr_block
  description       = "MSSQL from VPC"
}

resource "aws_vpc_security_group_ingress_rule" "redis_vpc" {
  security_group_id = aws_security_group.database.id
  ip_protocol       = "tcp"
  from_port         = 6379
  to_port           = 6379
  cidr_ipv4         = data.aws_vpc.prod.cidr_block
  description       = "Redis from VPC"
}

resource "aws_vpc_security_group_egress_rule" "database_all_out" {
  security_group_id = aws_security_group.database.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
  description       = "Allow all outbound"
}

# ---------------------------------------------------------------------------
# Data sources
# ---------------------------------------------------------------------------
data "aws_vpc" "prod" {
  tags = {
    Environment = "production"
  }
}

# ---------------------------------------------------------------------------
# SSM Session Manager endpoint – eliminates the need for open SSH/RDP ports
# by routing administrative sessions through SSM rather than the internet.
# ---------------------------------------------------------------------------
resource "aws_security_group" "ssm_endpoint" {
  name        = "megger-prod-ssm-endpoint-sg"
  description = "Allows HTTPS from VPC to SSM/EC2 VPC endpoints"
  vpc_id      = data.aws_vpc.prod.id

  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
    Purpose     = "ssm-endpoint"
  }
}

resource "aws_vpc_security_group_ingress_rule" "ssm_https_vpc" {
  security_group_id = aws_security_group.ssm_endpoint.id
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = data.aws_vpc.prod.cidr_block
  description       = "HTTPS from VPC for SSM endpoints"
}

resource "aws_vpc_security_group_egress_rule" "ssm_endpoint_all_out" {
  security_group_id = aws_security_group.ssm_endpoint.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
  description       = "Allow all outbound"
}

resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = data.aws_vpc.prod.id
  service_name        = "com.amazonaws.${var.aws_region}.ssm"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = data.aws_subnets.private.ids
  security_group_ids  = [aws_security_group.ssm_endpoint.id]
  private_dns_enabled = true

  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

resource "aws_vpc_endpoint" "ssm_messages" {
  vpc_id              = data.aws_vpc.prod.id
  service_name        = "com.amazonaws.${var.aws_region}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = data.aws_subnets.private.ids
  security_group_ids  = [aws_security_group.ssm_endpoint.id]
  private_dns_enabled = true

  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

resource "aws_vpc_endpoint" "ec2_messages" {
  vpc_id              = data.aws_vpc.prod.id
  service_name        = "com.amazonaws.${var.aws_region}.ec2messages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = data.aws_subnets.private.ids
  security_group_ids  = [aws_security_group.ssm_endpoint.id]
  private_dns_enabled = true

  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.prod.id]
  }

  tags = {
    Tier = "private"
  }
}
