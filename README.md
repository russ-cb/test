## Account 171892110317

| Category | Inferred Services | Known Resources / Findings |
|---|---|---|
| **Backup** | EBS Snapshots | 16 unencrypted EBS snapshots in eu-west-1 |
| **Compute** | EC2, SSM | 2 stopped EC2 instances; SSM coverage 47.6%; 1 instance without IAM instance profile |
| **Containers** | ECR | 2 ECR repos without scan-on-push |
| **Databases** | RDS | `megger-account-management-system-development` (not Multi-AZ); `mg-aim-test-kub-db` (not Multi-AZ); `mgproductionyeilddata1` (not Multi-AZ) |
| **Governance** | AWS Config, AWS Budgets, Cost Anomaly Detection | No Config rules; no Budgets; no Cost Anomaly Detection |
| **Networking** | VPC Security Groups | 6 security group rules open to 0.0.0.0/0 on sensitive ports |
| **Observability** | CloudWatch Logs | 9 log groups with no retention policy |
| **Organization** | AWS Organizations | No tag policies defined |
| **Serverless** | Lambda | 1 Lambda function on deprecated runtime |
| **Storage** | EBS, S3 | 1 unattached EBS volume; 1 unencrypted EBS volume; `megger-account-management-system-dev-s3` (no full public access block); 6 S3 buckets without versioning; 3 S3 buckets without lifecycle policies |

---

## Account 188248342913

| Category | Inferred Services | Known Resources / Findings |
|---|---|---|
| **Backup** | RDS Backup, AWS Backup | `megger-account-management-system-development` not covered by AWS Backup ⚠️ HIGH |
| **Compute** | EC2, SSM | SSM coverage 50.0% |
| **Containers** | ECR | 1 ECR repo without scan-on-push |
| **Databases** | RDS | `megger-account-management-system-production` (not Multi-AZ) |
| **Governance** | AWS Config, AWS Budgets, Cost Anomaly Detection | No Config rules; no Budgets; no Cost Anomaly Detection |
| **Networking** | VPC Security Groups | 35 security group rules open to 0.0.0.0/0 on sensitive ports ⚠️ HIGH — largest exposure in the estate |
| **Observability** | CloudWatch Logs | 7 log groups with no retention policy |
| **Organization** | AWS Organizations | No tag policies defined |
| **Storage** | EBS, S3 | 1 unattached EBS volume; `megger-account-management-system-prod-s3` (no full public access block) ⚠️ HIGH; 2 S3 buckets without versioning; 4 S3 buckets without lifecycle policies |

---

## Account 389656351913

| Category | Inferred Services | Known Resources / Findings |
|---|---|---|
| **Backup** | AWS Backup, RDS Backup | `megger-account-management-system-production` not covered by AWS Backup ⚠️ HIGH; `mgproductionyeilddata-prod` not covered by AWS Backup ⚠️ HIGH; **No AWS Backup plans exist**; **No resources protected by AWS Backup** ⚠️ HIGH |
| **Compute** | EC2, SSM | SSM coverage **0.0%** — no instances managed by SSM; 3 running instances without IAM instance profile |
| **Governance** | AWS Config, AWS Budgets, Cost Anomaly Detection | No Config rules; no Budgets; no Cost Anomaly Detection |
| **Networking** | VPC Security Groups | 5 security group rules open to 0.0.0.0/0 on sensitive ports |
| **Observability** | CloudWatch Alarms, CloudWatch Logs, CloudWatch Dashboards | **No CloudWatch alarms configured** ⚠️ HIGH; no dashboards; 3 running EC2 instances with zero alarm coverage |
| **Organization** | AWS Organizations, SCPs | No custom SCPs — only default `FullAWSAccess`; no tag policies |
| **Storage** | EBS | 3 unencrypted EBS volumes |

> ⚠️ **Most critical account** — zero backup coverage, zero SSM coverage, zero CloudWatch alarms, and no SCPs.

---

## Account 622662547233

| Category | Inferred Services | Known Resources / Findings |
|---|---|---|
| **Backup** | EBS Snapshots | 78 unencrypted EBS snapshots in eu-west-1 — largest snapshot exposure in the estate |
| **Compute** | EC2 | 3 stopped EC2 instances |
| **Governance** | AWS Config, Cost Anomaly Detection | No Config rules; no Cost Anomaly Detection *(no Budget finding — may already have one)* |
| **Networking** | VPC Security Groups | 15 security group rules open to 0.0.0.0/0 on sensitive ports |
| **Observability** | CloudWatch Logs, CloudWatch Dashboards | 1 log group with no retention policy; no CloudWatch dashboards |
| **Organization** | AWS Organizations, SCPs | No custom SCPs — only default `FullAWSAccess`; no tag policies |
| **Storage** | EBS | 5 unattached EBS volumes |

---

## Account 729242963210

*This account has the most findings and appears to be the most active/complex account.*

| Category | Inferred Services | Known Resources / Findings |
|---|---|---|
| **Compute** | EC2, SSM | SSM coverage data present (implied by findings pattern); instances running |
| **Governance** | AWS Config, AWS Budgets | No Config rules; no Budgets |
| **IAM** | IAM Users, Access Keys | Console user without MFA ⚠️ HIGH; 8 access keys older than 90 days |
| **Networking** | VPC Security Groups | Sensitive port exposure findings present |
| **Observability** | CloudWatch Logs | Large number of log groups (referenced in AI analysis as "relatively large") without retention policies |
| **Storage** | S3 | `megger-bloomfire-public` without full public access block ⚠️ HIGH |

> ⚠️ **Note:** The raw findings data attributes fewer explicit named findings to this account compared to others, but the AI analysis identifies it as the account with IAM credential risks and the `megger-bloomfire-public` S3 bucket.

---

## Cross-Account Summary

| AWS Service | Accounts Confirmed In Use |
|---|---|
| **EC2** | 171892110317, 188248342913, 389656351913, 622662547233 |
| **RDS** | 171892110317, 188248342913, 389656351913 |
| **S3** | 171892110317, 188248342913, 729242963210 |
| **EBS** | 171892110317, 188248342913, 389656351913, 622662547233 |
| **ECR** | 171892110317, 188248342913 |
| **Lambda** | 171892110317 |
| **CloudWatch** | 171892110317, 188248342913, 622662547233 (absent in 389656351913) |
| **AWS Backup** | Absent or incomplete in all accounts |
| **SSM** | Partial in 171892110317, 188248342913; absent in 389656351913 |
| **IAM** | All accounts (issues concentrated in 729242963210) |
| **VPC/Security Groups** | All accounts |

---
