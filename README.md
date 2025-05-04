This repository contains Terraform code to provision an EKS cluster and deploy a service, along with two GitHub Action pipelines for managing the infrastructure: **Terraform Plan** and **Terraform Apply**.

---

## Repository Structure

```
.
├── terraform/                # Folder containing Terraform code
│   ├── main.tf               # Main Terraform configuration
│   ├── variables.tf          # Input variables for Terraform
│   ├── outputs.tf            # Outputs for Terraform
│   ├── backend.tf            # Remote backend configuration
│   ├── variables.tfvars      # Variable values for Terraform
    └── README.md                 # Documentation for the repository
├── .github/workflows/        # GitHub Action pipelines
│   ├── terraform-plan.yml    # Pipeline for Terraform Plan
│   └── terraform-apply.yml   # Pipeline for Terraform Apply
├── README.md                 # Documentation for the repository
```

---

## Prerequisites

1. **AWS Account**:
   - Ensure you have an AWS account with permissions to create resources (EKS, VPC, IAM, etc.).

2. **Terraform Backend**:
   - Configure an S3 bucket and DynamoDB table for remote state storage and state locking.

3. **GitHub Secrets**:
   - Add the following secrets to your repository:
     - `AWS_ACCESS_KEY_ID`: Your AWS access key.
     - `AWS_SECRET_ACCESS_KEY`: Your AWS secret key.
     - `AWS_REGION`: The AWS region (e.g., `us-west-1`).
     - `EKS_CLUSTER_NAME`: The name of your EKS cluster.

---

## Terraform Code

The Terraform code in the `terraform/` folder provisions the following resources:
- **VPC**: A Virtual Private Cloud with public and private subnets.
- **EKS Cluster**: An Amazon EKS cluster.
- **Node Groups**: Worker nodes in private subnets.
- **IAM Roles**: Roles for the EKS cluster and worker nodes.

### Example `main.tf`:
```hcl
# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

provider "aws" {
  region = var.region
}

# Filter out local zones, which are not currently supported 
# with managed node groups
data "aws_availability_zones" "available" {
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

locals {
  cluster_name = "education-eks-${random_string.suffix.result}"
}

resource "random_string" "suffix" {
  length  = 8
  special = false
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.8.1"

  name = "education-vpc"

  cidr = "10.0.0.0/16"
  azs  = slice(data.aws_availability_zones.available.names, 0, 2)

  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.8.5"

  cluster_name    = local.cluster_name
  cluster_version = "1.29"

  cluster_endpoint_public_access           = true
  enable_cluster_creator_admin_permissions = true

  cluster_addons = {
    aws-ebs-csi-driver = {
      service_account_role_arn = module.irsa-ebs-csi.iam_role_arn
    }
  }

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_group_defaults = {
    ami_type = "AL2_x86_64"

  }

  eks_managed_node_groups = {
    one = {
      name = "node-group-1"

      instance_types = ["t3.small"]

      min_size     = 1
      max_size     = 3
      desired_size = 2

      labels = {
        role = "app"
      }
    }

    two = {
      name = "node-group-2"

      instance_types = ["t3.small"]

      min_size     = 1
      max_size     = 2
      desired_size = 1

      labels = {
        role = "app"
      }
    }
  }
}


# https://aws.amazon.com/blogs/containers/amazon-ebs-csi-driver-is-now-generally-available-in-amazon-eks-add-ons/ 
data "aws_iam_policy" "ebs_csi_policy" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

module "irsa-ebs-csi" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "5.39.0"

  create_role                   = true
  role_name                     = "AmazonEKSTFEBSCSIRole-${module.eks.cluster_name}"
  provider_url                  = module.eks.oidc_provider
  role_policy_arns              = [data.aws_iam_policy.ebs_csi_policy.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
}
```

---

## Pipelines

### 1. **Terraform Plan Pipeline**
This pipeline previews changes to the infrastructure.

#### Trigger:
- Automatically runs on pull requests to the `main` branch.

#### Workflow File: `.github/workflows/plan.yml`
```yaml
name: Terraform Plan

on:
  pull_request:
    branches:
      - main

jobs:
  terraform-plan:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: 1.5.0

      - name: Initialize Terraform
        run: terraform init
        env:
          AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}

      - name: Terraform Plan
        run: terraform plan
        env:
          AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
```

---

### 2. **Terraform Apply Pipeline**
This pipeline applies the Terraform configuration to provision or update the infrastructure.

#### Trigger:
- Manually triggered via the **Actions** tab in GitHub.

#### Workflow File: `.github/workflows/apply.yml`
```yaml
name: Terraform Apply

on:
  workflow_dispatch:
    inputs:
      confirm:
        description: "Confirm Apply"
        required: true
        default: "yes"

jobs:
  terraform-apply:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: 1.5.0

      - name: Initialize Terraform
        run: terraform init
        env:
          AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}

      - name: Terraform Apply
        if: ${{ github.event.inputs.confirm == 'yes' }}
        run: terraform apply -auto-approve
        env:
          AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
```

---

## Usage

### 1. **Terraform Plan**
- Create a pull request to the `main` branch.
- The pipeline will automatically run and generate a Terraform plan.
- Review the plan in the **Actions** tab.

### 2. **Terraform Apply**
- Go to the **Actions** tab in GitHub.
- Select the **Terraform Apply** workflow.
- Click **Run workflow** and confirm the apply action.
- The pipeline will apply the Terraform configuration.

---

## Best Practices

1. **Secure Secrets**:
   - Use GitHub Secrets to store sensitive information like AWS credentials.

2. **Review Plans**:
   - Always review the Terraform plan before applying changes.

3. **State Management**:
   - Use a remote backend (e.g., S3) to manage Terraform state securely.

---

## Troubleshooting

1. **Pipeline Fails on `terraform init`**:
   - Ensure the S3 bucket and DynamoDB table for the Terraform backend exist and are correctly configured.

2. **Pipeline Fails on `terraform apply`**:
   - Check the Terraform plan for errors.
   - Ensure the AWS credentials have sufficient permissions.

3. **EKS Cluster Issues**:
   - Verify the EKS cluster configuration and ensure the kubeconfig is updated.
