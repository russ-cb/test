# Security Remediation – Terraform

This directory contains the Terraform configurations that implement the security
remediations identified in the risk report.  Each sub-directory corresponds to
an AWS account or environment.

```
terraform/
├── production/              # Production account remediations
│   ├── providers.tf         # AWS provider + DR-region provider
│   ├── variables.tf
│   ├── s3.tf                # Risk 1 – S3 Block Public Access
│   ├── backup.tf            # Risk 2 – AWS Backup plan (daily, 30-day, cross-region)
│   ├── rds.tf               # Risk 2 & 5 – RDS Multi-AZ + backup retention
│   └── security_groups.tf   # Risk 3 – Replace 0.0.0.0/0 rules with scoped rules
│
├── development/             # Development account remediations
│   ├── providers.tf
│   ├── variables.tf
│   ├── s3.tf                # Risk 1 – S3 Block Public Access (dev bucket)
│   └── backup.tf            # Risk 2 – AWS Backup plan (daily, 14-day)
│
└── account-389656351913/    # Unprotected account remediations (Risk 4)
    ├── providers.tf
    ├── variables.tf
    ├── backup.tf            # AWS Backup plan (daily + weekly retention)
    ├── iam.tf               # EC2 IAM instance profiles for SSM + CW agent
    ├── cloudwatch.tf        # CloudWatch alarms + agent configuration
    └── ssm.tf               # SSM enrollment, Session Manager prefs, VPC endpoints
```

## Usage

```bash
# Production
cd terraform/production
terraform init
terraform plan -var="vpc_cidr=10.0.0.0/16" -var='admin_ip_cidrs=["203.0.113.0/24"]'
terraform apply

# Development
cd terraform/development
terraform init
terraform plan -var="vpc_cidr=10.1.0.0/16"
terraform apply

# Account 389656351913
cd terraform/account-389656351913
terraform init
terraform plan \
  -var="vpc_cidr=10.2.0.0/16" \
  -var='ec2_instance_ids=["i-0123456789abcdef0"]'
terraform apply
```

## Risks Addressed

| Risk | Severity | Terraform Files |
|------|----------|-----------------|
| 1. Production S3 Bucket Publicly Accessible | HIGH | `production/s3.tf`, `development/s3.tf` |
| 2. Production RDS Not Covered by AWS Backup | HIGH | `production/backup.tf`, `production/rds.tf`, `development/backup.tf` |
| 3. Security Groups Open to Internet | HIGH | `production/security_groups.tf` |
| 4. Account 389656351913 No Coverage | HIGH | `account-389656351913/backup.tf`, `account-389656351913/iam.tf`, `account-389656351913/cloudwatch.tf`, `account-389656351913/ssm.tf` |
| 5. Production RDS Not Multi-AZ | MEDIUM | `production/rds.tf` |
