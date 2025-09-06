# AWS Permissions Guide for QuantTrader-K8s-Simulator

## Overview

This guide outlines the AWS permissions required for the QuantTrader-K8s-Simulator project setup. The setup script requires specific permissions to create and manage AWS resources.

## Required AWS Permissions

### 1. S3 Permissions
**Purpose**: Create and manage Terraform state storage

**Required Actions**:
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:CreateBucket",
                "s3:DeleteBucket",
                "s3:GetBucketLocation",
                "s3:GetBucketVersioning",
                "s3:PutBucketVersioning",
                "s3:GetBucketEncryption",
                "s3:PutBucketEncryption",
                "s3:ListBucket",
                "s3:GetObject",
                "s3:PutObject",
                "s3:DeleteObject"
            ],
            "Resource": [
                "arn:aws:s3:::quanttrader-tf-state-*",
                "arn:aws:s3:::quanttrader-tf-state-*/*"
            ]
        }
    ]
}
```

### 2. DynamoDB Permissions
**Purpose**: Create and manage Terraform state locking

**Required Actions**:
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "dynamodb:CreateTable",
                "dynamodb:DeleteTable",
                "dynamodb:DescribeTable",
                "dynamodb:ListTables",
                "dynamodb:GetItem",
                "dynamodb:PutItem",
                "dynamodb:DeleteItem",
                "dynamodb:UpdateItem"
            ],
            "Resource": [
                "arn:aws:dynamodb:us-west-2:*:table/quanttrader-tf-lock"
            ]
        }
    ]
}
```

### 3. CloudWatch Permissions
**Purpose**: Create billing alarms and monitoring

**Required Actions**:
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "cloudwatch:PutMetricAlarm",
                "cloudwatch:DeleteAlarms",
                "cloudwatch:DescribeAlarms",
                "cloudwatch:ListMetrics",
                "cloudwatch:GetMetricStatistics"
            ],
            "Resource": "*"
        }
    ]
}
```

### 4. SNS Permissions
**Purpose**: Create billing alert notifications

**Required Actions**:
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "sns:CreateTopic",
                "sns:DeleteTopic",
                "sns:Subscribe",
                "sns:Unsubscribe",
                "sns:ListTopics",
                "sns:GetTopicAttributes",
                "sns:SetTopicAttributes"
            ],
            "Resource": [
                "arn:aws:sns:us-west-2:*:quanttrader-billing-alerts"
            ]
        }
    ]
}
```

### 5. Cost Explorer Permissions
**Purpose**: Access billing and cost information

**Required Actions**:
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ce:GetCostAndUsage",
                "ce:GetUsageReport",
                "ce:ListCostCategoryDefinitions"
            ],
            "Resource": "*"
        }
    ]
}
```

## Complete IAM Policy

Here's a complete IAM policy that includes all required permissions:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "S3TerraformState",
            "Effect": "Allow",
            "Action": [
                "s3:CreateBucket",
                "s3:DeleteBucket",
                "s3:GetBucketLocation",
                "s3:GetBucketVersioning",
                "s3:PutBucketVersioning",
                "s3:GetBucketEncryption",
                "s3:PutBucketEncryption",
                "s3:ListBucket",
                "s3:GetObject",
                "s3:PutObject",
                "s3:DeleteObject"
            ],
            "Resource": [
                "arn:aws:s3:::quanttrader-tf-state-*",
                "arn:aws:s3:::quanttrader-tf-state-*/*"
            ]
        },
        {
            "Sid": "DynamoDBTerraformLock",
            "Effect": "Allow",
            "Action": [
                "dynamodb:CreateTable",
                "dynamodb:DeleteTable",
                "dynamodb:DescribeTable",
                "dynamodb:ListTables",
                "dynamodb:GetItem",
                "dynamodb:PutItem",
                "dynamodb:DeleteItem",
                "dynamodb:UpdateItem"
            ],
            "Resource": [
                "arn:aws:dynamodb:us-west-2:*:table/quanttrader-tf-lock"
            ]
        },
        {
            "Sid": "CloudWatchBillingAlarms",
            "Effect": "Allow",
            "Action": [
                "cloudwatch:PutMetricAlarm",
                "cloudwatch:DeleteAlarms",
                "cloudwatch:DescribeAlarms",
                "cloudwatch:ListMetrics",
                "cloudwatch:GetMetricStatistics"
            ],
            "Resource": "*"
        },
        {
            "Sid": "SNSBillingAlerts",
            "Effect": "Allow",
            "Action": [
                "sns:CreateTopic",
                "sns:DeleteTopic",
                "sns:Subscribe",
                "sns:Unsubscribe",
                "sns:ListTopics",
                "sns:GetTopicAttributes",
                "sns:SetTopicAttributes"
            ],
            "Resource": [
                "arn:aws:sns:us-west-2:*:quanttrader-billing-alerts"
            ]
        },
        {
            "Sid": "CostExplorerAccess",
            "Effect": "Allow",
            "Action": [
                "ce:GetCostAndUsage",
                "ce:GetUsageReport",
                "ce:ListCostCategoryDefinitions"
            ],
            "Resource": "*"
        }
    ]
}
```

## Setting Up AWS Permissions

### Option 1: Using AWS Console

1. **Navigate to IAM Console**
   - Go to AWS IAM Console
   - Click "Policies" → "Create Policy"

2. **Create Custom Policy**
   - Click "JSON" tab
   - Paste the complete IAM policy above
   - Name the policy: `QuantTrader-K8s-Setup-Policy`

3. **Attach Policy to User**
   - Go to "Users" → Select your user
   - Click "Add permissions" → "Attach policies directly"
   - Select `QuantTrader-K8s-Setup-Policy`

### Option 2: Using AWS CLI

```bash
# Create the policy
aws iam create-policy \
  --policy-name QuantTrader-K8s-Setup-Policy \
  --policy-document file://quanttrader-policy.json

# Attach policy to user
aws iam attach-user-policy \
  --user-name quanttrader-dev \
  --policy-arn arn:aws:iam::YOUR-ACCOUNT-ID:policy/QuantTrader-K8s-Setup-Policy
```

### Option 3: Using Terraform

```hcl
resource "aws_iam_policy" "quanttrader_setup" {
  name        = "QuantTrader-K8s-Setup-Policy"
  description = "Policy for QuantTrader-K8s-Simulator setup"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # ... (include the complete policy from above)
    ]
  })
}

resource "aws_iam_user_policy_attachment" "quanttrader_setup" {
  user       = "quanttrader-dev"
  policy_arn = aws_iam_policy.quanttrader_setup.arn
}
```

## Troubleshooting Permission Issues

### Common Error Messages

1. **"AccessDenied" when creating S3 bucket**
   ```
   User is not authorized to perform: s3:CreateBucket
   ```
   **Solution**: Add `s3:CreateBucket` permission to your IAM policy

2. **"AccessDenied" when creating DynamoDB table**
   ```
   User is not authorized to perform: dynamodb:CreateTable
   ```
   **Solution**: Add `dynamodb:CreateTable` permission to your IAM policy

3. **"AccessDenied" when creating CloudWatch alarms**
   ```
   User is not authorized to perform: cloudwatch:PutMetricAlarm
   ```
   **Solution**: Add `cloudwatch:PutMetricAlarm` permission to your IAM policy

### Testing Permissions

Use these commands to test your permissions:

```bash
# Test S3 permissions
aws s3 ls --profile quanttrader-dev

# Test DynamoDB permissions
aws dynamodb list-tables --profile quanttrader-dev

# Test CloudWatch permissions
aws cloudwatch describe-alarms --profile quanttrader-dev

# Test SNS permissions
aws sns list-topics --profile quanttrader-dev
```

### Manual Resource Creation

If you don't have the required permissions, you can create resources manually:

#### Create S3 Bucket
```bash
aws s3 mb s3://quanttrader-tf-state-$(date +%s) --profile quanttrader-dev --region us-west-2
aws s3api put-bucket-versioning --bucket quanttrader-tf-state-$(date +%s) --versioning-configuration Status=Enabled --profile quanttrader-dev
aws s3api put-bucket-encryption --bucket quanttrader-tf-state-$(date +%s) --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}' --profile quanttrader-dev
```

#### Create DynamoDB Table
```bash
aws dynamodb create-table \
  --table-name quanttrader-tf-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --profile quanttrader-dev \
  --region us-west-2
```

## Security Best Practices

1. **Principle of Least Privilege**: Only grant the minimum permissions required
2. **Resource-Specific Permissions**: Limit permissions to specific resources when possible
3. **Regular Audits**: Review and audit permissions regularly
4. **Use IAM Roles**: Consider using IAM roles instead of user policies for better security
5. **Enable MFA**: Enable Multi-Factor Authentication for additional security

## Cost Considerations

- **S3 Storage**: Minimal cost for Terraform state files
- **DynamoDB**: Pay-per-request pricing, very low cost for state locking
- **CloudWatch**: Free tier includes 10 alarms
- **SNS**: Free tier includes 1,000,000 requests per month

## Next Steps

After setting up permissions:

1. Run the setup script: `./scripts/setup-1.1.sh`
2. Verify permissions: `./scripts/verify-1.1.sh`
3. Check AWS resources: `aws s3 ls --profile quanttrader-dev`
4. Proceed to Phase 1.2 setup

## Support

If you encounter permission issues:

1. Check the error messages in the setup script output
2. Verify your IAM policy includes all required permissions
3. Test individual AWS service access using the commands above
4. Contact your AWS administrator if you need additional permissions
