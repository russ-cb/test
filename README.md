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

Based on the discovery data, **none of the five AWS accounts are managed by Infrastructure as Code**. Every account shows zero IaC coverage across all detection methods.

| Account ID | CloudFormation Stacks | CDK Detected | Terraform Detected | IaC Tag Coverage |
|---|---|---|---|---|
| 171892110317 | 0 | No | No | 0% |
| 188248342913 | 0 | No | No | 0% |
| 389656351913 | 0 | No | No | 0% |
| 622662547233 | 0 | No | No | 0% |
| 729242963210 | 0 | No | No | 0% |

### Key Observations

- **No CloudFormation stacks** exist in any account — ruling out native AWS IaC
- **No CDK usage detected** — CDK would typically leave identifiable CloudFormation stacks and toolkit resources
- **No Terraform state or tagging signals detected** across all five accounts
- **0% IaC tag coverage** in every account, meaning resources lack the tagging patterns typically associated with Terraform (`terraform-managed`) or CDK/CloudFormation deployments

### Why This Matters

With **4,446 resources deployed entirely outside of IaC**, the environment carries significant operational risk:
- No repeatable, version-controlled deployment process
- Configuration drift cannot be detected or prevented
- Disaster recovery and environment rebuilding would be largely manual
- This compounds existing governance findings — notably the **absence of AWS Config rules** across four accounts, meaning drift goes undetected at both the IaC and compliance layer

### Recommended Alarms by Category

#### 🖥️ EC2 / Compute
*Particularly critical for account 389656351913 (0% alarm coverage)*

| Alarm | Metric | Threshold | Priority |
|---|---|---|---|
| High CPU | `CPUUtilization` | >80% for 5 mins | High |
| Instance Status Check Failed | `StatusCheckFailed_Instance` | ≥1 for 2 mins | High |
| System Status Check Failed | `StatusCheckFailed_System` | ≥1 for 2 mins | High |
| High Memory (requires CW Agent) | `mem_used_percent` | >85% for 5 mins | Medium |
| Disk Space (requires CW Agent) | `disk_used_percent` | >85% for 5 mins | Medium |

**Remediation actions:**
- **High CPU / Memory:** Investigate runaway processes via SSM Session Manager (once SSM coverage is improved — currently 0% in account 389656351913). Consider instance right-sizing or Auto Scaling.
- **Status Check Failed (Instance):** Trigger an SNS notification to ops team; attempt instance stop/start via Lambda automation. If persistent, raise AWS Support case.
- **Status Check Failed (System):** AWS infrastructure issue — trigger automated instance recovery using the built-in **EC2 Recover** alarm action (`arn:aws:automate:<region>:ec2:recover`).
- **Disk Space:** Connect via SSM, identify large files/logs, and clean up. Review CloudWatch log group retention policies (directly relevant given the 17 log groups with infinite retention).

---

#### 🗄️ RDS / Databases
*Relevant across accounts with unprotected, non-Multi-AZ instances: `megger-account-management-system-development`, `megger-account-management-system-production`, `mgproductionyeilddata1`, `mg-aim-test-kub-db`*

| Alarm | Metric | Threshold | Priority |
|---|---|---|---|
| High CPU | `CPUUtilization` | >80% for 5 mins | High |
| Low Free Storage | `FreeStorageSpace` | <10% of allocated | High |
| High DB Connections | `DatabaseConnections` | >80% of max_connections | High |
| Low Freeable Memory | `FreeableMemory` | <256MB for 5 mins | Medium |
| Read/Write Latency | `ReadLatency` / `WriteLatency` | >100ms for 5 mins | Medium |

**Remediation actions:**
- **Low Free Storage:** Immediately enable storage autoscaling on the RDS instance, or manually scale storage. Review and purge old data or enable archiving.
- **High Connections:** Investigate application connection pooling. Consider deploying **RDS Proxy** to manage connection limits.
- **High CPU / Latency:** Review slow query logs, optimise queries, or scale instance class. For production instances (`megger-account-management-system-production`, `mgproductionyeilddata-prod`), this is especially critical given they also lack Multi-AZ and AWS Backup coverage — a failure here has no safety net.

---

#### 🪣 S3 / Storage
*Relevant for `megger-account-management-system-dev-s3` and `megger-account-management-system-prod-s3` (both lack public access blocks)*

| Alarm | Metric | Threshold | Priority |
|---|---|---|---|
| 4xx Errors (potential misconfiguration/attack) | `4xxErrors` | >50 in 5 mins | Medium |
| 5xx Errors (service issues) | `5xxErrors` | >10 in 5 mins | Medium |

**Remediation actions:**
- **4xx spike:** Investigate for bucket policy misconfigurations or potential enumeration/scraping attempts. Review S3 Access Logs and CloudTrail for the source IPs.
- **5xx spike:** Likely an AWS-side issue; monitor AWS Service Health Dashboard and retry logic in the application.

---

#### 🔐 Security / IAM
*Relevant across all accounts given open security groups (71 rules open to 0.0.0.0/0) and IAM hygiene issues in account 729242963210*

| Alarm | Metric / Filter | Threshold | Priority |
|---|---|---|---|
| Root account usage | CloudTrail → `userIdentity.type = Root` | Any occurrence | High |
| Console login without MFA | CloudTrail → `ConsoleLogin` + `mfaUsed = false` | Any occurrence | High |
| Security group changes | CloudTrail → `AuthorizeSecurityGroupIngress` | Any occurrence | High |
| Unauthorised API calls | CloudTrail → `errorCode = AccessDenied` | >10 in 5 mins | Medium |
| IAM policy changes | CloudTrail → `PutUserPolicy`, `AttachRolePolicy` etc. | Any occurrence | Medium |

> These alarms require **CloudWatch Metric Filters** on CloudTrail logs. CloudTrail must be enabled and delivering to CloudWatch Logs — confirm this is the case across all accounts.

**Remediation actions:**
- **Root account usage:** Immediately investigate via CloudTrail. Rotate root credentials, verify MFA is enabled on root, and notify the security team. This should be treated as a potential incident.
- **Console login without MFA:** Lock the account session, enforce MFA via IAM policy (`aws:MultiFactorAuthPresent = true` condition), and notify the user. Directly addresses the HIGH finding in account 729242963210.
- **Security group changes:** Review the change in CloudTrail, revert if unauthorised. Implement AWS Config rule `restricted-ssh` and `vpc-sg-open-only-to-authorized-ports` to auto-remediate.
- **Unauthorised API calls:** Investigate source identity in CloudTrail. May indicate compromised credentials or misconfigured application roles.

---

#### 💰 Cost / Billing
*Relevant across accounts 171892110317, 188248342913, 389656351913, and 729242963210 — all missing AWS Budgets*

| Alarm | Metric | Threshold | Priority |
|---|---|---|---|
| Estimated charges | `EstimatedCharges` (Billing namespace) | >$X (define per account) | Medium |

**Remediation actions:**
- **Billing spike:** Review Cost Explorer for unexpected service usage. Cross-reference with the open security groups — a compromised instance could be running crypto mining or data exfiltration at cost. Immediately investigate and consider enabling **Cost Anomaly Detection** (currently missing across multiple accounts).

---

### Implementation Recommendations

1. **Start with account 389656351913** — it has zero alarms and running EC2 instances. This is the highest priority gap.
2. **Use CloudFormation or Terraform** to deploy alarms consistently — noting that currently **none of the five accounts use any IaC** (0% IaC coverage across all accounts), so this would also begin addressing the broader IaC gap.
3. **Create a central SNS topic per account** (e.g., `ops-alerts`) and route all alarms to it, with subscriptions for email and/or PagerDuty/Slack via Lambda.
4. **Deploy the CloudWatch Agent** on all EC2 instances via SSM (once SSM coverage is improved from its current 0–50% range) to unlock memory and disk metrics.
5. **Define a runbook** for each alarm type so on-call engineers have clear remediation steps — the actions above can serve as the starting framework.
