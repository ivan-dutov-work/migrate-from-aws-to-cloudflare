# Deployment Instructions

Step-by-step guide to deploy the Gallery static site on **AWS** or **Cloudflare**. Both paths assume you have Terraform ≥ 1.5 installed and the Astro site builds successfully.

---

## Prerequisites (both platforms)

1. **Build the site** — this produces a `dist/` directory with static assets:

   ```bash
   bun install
   bun run build
   ```

2. **Install Terraform** (if not already):

   ```bash
   # macOS
   brew install terraform

   # Windows (winget)
   winget install Hashicorp.Terraform

   # Or download from https://developer.hashicorp.com/terraform/downloads
   ```

---

## Section 0 — Remote State Setup (One-Time)

**⚠️ Important:** Complete this section BEFORE deploying your infrastructure if you want persistent Terraform state storage across team members and CI/CD environments.

### Why Remote State?

- **Team Collaboration** — Multiple team members can work on infrastructure safely
- **State Locking** — Prevents concurrent modifications that could corrupt state
- **Persistence** — State survives local machine failures and is accessible from anywhere
- **CI/CD Integration** — GitHub Actions can manage infrastructure with persistent state
- **Disaster Recovery** — Versioned state files allow rollback if corruption occurs

### 0.1 — Deploy State Infrastructure

The Terraform configuration includes resources for state storage (S3 bucket + DynamoDB table). Deploy these first with **local state**, then migrate to remote state.

```bash
cd terraform

# Verify backend is commented out in providers.tf
grep -A 6 'backend "s3"' providers.tf
# Should show commented lines or nothing

# Initialize and deploy state infrastructure
terraform init
terraform plan   # Review: should show ~15 resources (12 for site + 3 for state)
terraform apply  # Creates gallery-terraform-state bucket + gallery-terraform-locks table
```

**What gets created:**
- **S3 Bucket:** `gallery-terraform-state` (encrypted, versioned, lifecycle protection)
- **DynamoDB Table:** `gallery-terraform-locks` (state locking, pay-per-request billing)
- Both resources have `prevent_destroy = true` to prevent accidental deletion

### 0.2 — Enable Remote State Backend

Uncomment the backend configuration in `providers.tf`:

```bash
cd terraform
# Edit providers.tf and uncomment the backend "s3" block (lines 14-20)
```

The backend block should look like:
```hcl
backend "s3" {
  bucket         = "gallery-terraform-state"
  key            = "gallery/terraform.tfstate"
  region         = "us-east-1"
  dynamodb_table = "gallery-terraform-locks"
  encrypt        = true
}
```

### 0.3 — Migrate Local State to S3

**⚠️ Backup first:**
```bash
cp terraform.tfstate terraform.tfstate.backup.local
cp .terraform.tfstate.backup .terraform.tfstate.backup.local2
```

**Migrate state:**
```bash
terraform init -migrate-state
```

You'll see:
```
Initializing the backend...
Terraform has detected that the configuration specified for the backend
has changed. Terraform will now migrate the state to the new backend.

Do you want to copy existing state to the new backend?
  Enter a value: yes

Successfully configured the backend "s3"!
```

### 0.4 — Verify Remote State

**1. Check S3 bucket:**
```bash
aws s3 ls s3://gallery-terraform-state/gallery/
# Should show: terraform.tfstate
```

**2. Test state locking:**
```bash
# Terminal 1
terraform plan

# Terminal 2 (while Terminal 1 is running)
terraform plan
# Should wait with message: "Acquiring state lock..."
```

**3. Verify state is readable:**
```bash
terraform state list
# Should show all resources (S3 bucket, CloudFront, DynamoDB, etc.)
```

**4. Clean up local state files (optional):**
```bash
# After confirming remote state works
rm terraform.tfstate.backup.local*
# Keep terraform.tfstate.backup.local if you want an extra backup
```

### 0.5 — Team Member Onboarding

For new team members or other machines:

```bash
cd terraform
terraform init  # Automatically connects to remote state
terraform plan  # Should see "No changes" if state is current
```

No migration needed — backend config in `providers.tf` tells Terraform where to find state.

### 0.6 — Troubleshooting

**"Error acquiring state lock"**
- Someone else is running Terraform, or a previous run crashed
- Check DynamoDB table for stuck locks: `aws dynamodb scan --table-name gallery-terraform-locks`
- Force unlock (last resort): `terraform force-unlock <LOCK_ID>`

**"Backend configuration changed"**
- Run `terraform init -reconfigure` to reinitialize

**State file is empty or missing resources**
- Restore from S3 version history:
  ```bash
  aws s3api list-object-versions --bucket gallery-terraform-state --prefix gallery/
  aws s3api get-object --bucket gallery-terraform-state --key gallery/terraform.tfstate --version-id <VERSION_ID> terraform.tfstate
  ```

**Cannot destroy state bucket (prevent_destroy)**
- Intentional protection. To destroy:
  ```bash
  # Remove lifecycle block from main.tf, then:
  terraform apply
  terraform destroy
  ```

---

## Section 1 — AWS Deployment

### Architecture

```
User → Route 53 (DNS) → CloudFront (CDN + TLS) → S3 (private bucket, OAC)
                              ↑
                      ACM Certificate (us-east-1)
```

### 1.0 — Automated Deployment with GitHub Actions

The repository includes GitHub Actions workflows for automated deployment. This is the **recommended approach** for regular site updates.

#### Benefits
- ✅ No local AWS CLI setup required
- ✅ Secure OIDC authentication (no long-lived credentials)
- ✅ Consistent deployment process
- ✅ One-click deployments from GitHub UI
- ✅ Automatic CloudFront cache invalidation

#### Prerequisites

**1. Deploy infrastructure manually first** (one-time setup)

Follow sections 1.1–1.3 below to deploy the AWS infrastructure using Terraform locally. You need the S3 bucket and CloudFront distribution to exist before the GitHub Action can deploy site updates.

**2. Create AWS IAM OIDC Identity Provider** (one-time)

```bash
# Run this in your terminal (requires AWS CLI configured)
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1 \
  --region us-east-1
```

**3. Create IAM Role for GitHub Actions**

Create a file `github-actions-trust-policy.json`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::YOUR_ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:YOUR_GITHUB_USERNAME/YOUR_REPO_NAME:*"
        }
      }
    }
  ]
}
```

Replace `YOUR_ACCOUNT_ID`, `YOUR_GITHUB_USERNAME`, and `YOUR_REPO_NAME`, then create the role:

```bash
# Get your AWS account ID
aws sts get-caller-identity --query Account --output text

# Create the role
aws iam create-role \
  --role-name GitHubActionsDeployRole \
  --assume-role-policy-document file://github-actions-trust-policy.json

# Get the Role ARN (save this for GitHub Secrets)
aws iam get-role --role-name GitHubActionsDeployRole --query 'Role.Arn' --output text
```

**4. Attach permissions to the role**

Create a file `github-actions-permissions.json`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:DeleteObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::YOUR_BUCKET_NAME",
        "arn:aws:s3:::YOUR_BUCKET_NAME/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "cloudfront:CreateInvalidation",
        "cloudfront:GetInvalidation"
      ],
      "Resource": "arn:aws:cloudfront::YOUR_ACCOUNT_ID:distribution/YOUR_DISTRIBUTION_ID"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::gallery-terraform-state",
        "arn:aws:s3:::gallery-terraform-state/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "dynamodb:PutItem",
        "dynamodb:GetItem",
        "dynamodb:DeleteItem"
      ],
      "Resource": "arn:aws:dynamodb:us-east-1:YOUR_ACCOUNT_ID:table/gallery-terraform-locks"
    }
  ]
}
```

Replace `YOUR_BUCKET_NAME`, `YOUR_ACCOUNT_ID`, and `YOUR_DISTRIBUTION_ID`, then attach:

```bash
aws iam put-role-policy \
  --role-name GitHubActionsDeployRole \
  --policy-name DeployPolicy \
  --policy-document file://github-actions-permissions.json
```

**5. Configure GitHub Secrets**

Go to your GitHub repository → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**

Add these secrets:

| Secret Name | Value | How to get it |
|-------------|-------|---------------|
| `AWS_ROLE_ARN` | `arn:aws:iam::123456789012:role/GitHubActionsDeployRole` | From step 3 above |
| `AWS_REGION` | `us-east-1` | Your AWS region |
| `S3_BUCKET_NAME` | `gallery-assets` | From your `terraform.tfvars` |
| `CLOUDFRONT_DISTRIBUTION_ID` | `E1A2B3C4D5E6F7` | Run `terraform output cloudfront_distribution_id` in `terraform/aws/` |

For the **infrastructure workflow** (optional), also add:

| Secret Name | Value |
|-------------|-------|
| `TF_VAR_DOMAIN_NAME` | `gallery.example.com` |
| `TF_VAR_HOSTED_ZONE_ID` | `Z0123456789ABCDEFGHIJ` |
| `TF_VAR_BUCKET_NAME` | `gallery-assets` |

#### Deploying the Site

1. Go to your GitHub repository → **Actions** tab
2. Select **Deploy Site to AWS** workflow
3. Click **Run workflow** → **Run workflow**
4. Wait 2–3 minutes for the build and deployment to complete
5. Check the workflow summary for the deployment status
6. Visit your domain — the site should be live in 1–2 minutes

#### Deploying Infrastructure (Advanced)

The **Deploy Infrastructure to AWS** workflow is available for infrastructure changes. After completing **Section 0** (remote state setup), this workflow will use persistent S3-backed state.

**Benefits with remote state:**
- ✅ State persists between workflow runs
- ✅ Safe concurrent access with state locking
- ✅ Full infrastructure lifecycle management via GitHub Actions

**Prerequisites:**
- Complete **Section 0** to set up remote state
- Ensure GitHub Actions IAM role has state bucket/table permissions (see step 4 above)
- Uncomment the backend block in `terraform/providers.tf`

To use it:
1. Actions tab → **Deploy Infrastructure to AWS**
2. Select action: **plan** (preview) or **apply** (deploy)
3. Review the output in the workflow summary

**Note:** For infrastructure changes, local Terraform is still recommended for faster feedback and easier debugging.

---

### 1.1 — AWS Prerequisites (Manual Deployment)

| Requirement | How to get it |
|---|---|
| AWS CLI configured | `aws configure` — needs `Access Key ID` and `Secret Access Key` |
| Route 53 Hosted Zone | Create one for your domain in AWS Console → Route 53 → Hosted Zones. Copy the **Hosted Zone ID**. |
| Domain nameservers | Point your registrar's NS records to the four Route 53 nameservers shown in the Hosted Zone. |

### 1.2 — Create a `terraform.tfvars` file

```bash
cd terraform/aws
```

Create `terraform.tfvars`:

```hcl
domain_name    = "gallery.example.com"
hosted_zone_id = "Z0123456789ABCDEFGHIJ"
bucket_name    = "gallery-assets"
```

> **Note:** S3 bucket names are globally unique. Pick something unlikely to collide.

### 1.3 — Deploy the infrastructure

```bash
# Initialize providers
terraform init

# Preview what will be created (~12 resources)
terraform plan

# Apply — this will:
#   1. Create the S3 bucket (private, versioned, all public access blocked)
#   2. Request an ACM certificate in us-east-1
#   3. Create DNS validation records in Route 53
#   4. Wait for certificate validation (2–5 minutes)
#   5. Create a CloudFront distribution with Origin Access Control (OAC)
#   6. Create Route 53 A + AAAA alias records pointing to CloudFront
terraform apply
```

> **Heads-up:** The `aws_acm_certificate_validation` resource blocks until the certificate is validated. This typically takes 2–5 minutes but can occasionally take longer. Don't interrupt it.

### 1.4 — Upload the site to S3

After `terraform apply` completes, sync the Astro build output to S3:

```bash
aws s3 sync ../../dist/ s3://gallery-assets --delete
```

Replace `gallery-assets` with your actual bucket name.

### 1.5 — Invalidate the CloudFront cache

Grab the distribution ID from the Terraform output:

```bash
terraform output cloudfront_distribution_id
```

Then invalidate:

```bash
aws cloudfront create-invalidation \
  --distribution-id <DISTRIBUTION_ID> \
  --paths "/*"
```

### 1.6 — Verify

Open `https://gallery.example.com` (your domain). You should see the site served over HTTPS with a valid certificate.

### 1.7 — Updating the site

For every subsequent deploy, repeat steps 1.4 and 1.5:

```bash
bun run build
aws s3 sync ../../dist/ s3://gallery-assets --delete
aws cloudfront create-invalidation --distribution-id <DISTRIBUTION_ID> --paths "/*"
```

### 1.8 — Tear down

```bash
# Empty the bucket first (Terraform can't delete non-empty buckets)
aws s3 rm s3://gallery-assets --recursive

# Destroy all resources
terraform destroy
```
