README: Terraform Plan and Apply Pipelines for EKS Service
This repository contains two GitHub Actions pipelines for managing an EKS service using Terraform. The pipelines are designed to handle infrastructure provisioning and updates in a structured and secure manner.

Pipelines Overview
1. Terraform Plan Pipeline
Purpose: To preview changes to the infrastructure without applying them.
Trigger: Automatically runs on pull requests to the main branch.
Key Steps:
Initializes Terraform.
Runs terraform plan to generate an execution plan.
Outputs the plan for review.
2. Terraform Apply Pipeline
Purpose: To apply the Terraform configuration and provision/update the infrastructure.
Trigger: Manually triggered via the Actions tab in GitHub.
Key Steps:
Initializes Terraform.
Applies the Terraform configuration using terraform apply.
Prerequisites
AWS Credentials:

Store your AWS credentials (AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY) as GitHub Secrets.
Terraform Backend:

Ensure the Terraform state is stored remotely in an S3 bucket with a DynamoDB table for state locking.
EKS Cluster:

The pipelines assume an existing EKS cluster or Terraform configuration to create one.
Usage
1. Terraform Plan
Create a pull request to the main branch.
The pipeline will automatically run and generate a Terraform plan.
Review the plan in the Actions tab.
2. Terraform Apply
Go to the Actions tab in GitHub.
Select the Terraform Apply workflow.
Click Run workflow and confirm the apply action.
The pipeline will apply the Terraform configuration.

Best Practices

Secure Secrets:
Use GitHub Secrets to store sensitive information like AWS credentials.

Review Plans:
Always review the Terraform plan before applying changes.

State Management:
Use a remote backend (e.g., S3) to manage Terraform state securely.

Troubleshooting

Pipeline Fails on terraform init:
Ensure the S3 bucket and DynamoDB table for the Terraform backend exist and are correctly configured.

Pipeline Fails on terraform apply:
Check the Terraform plan for errors.
Ensure the AWS credentials have sufficient permissions.

EKS Cluster Issues:
Verify the EKS cluster configuration and ensure the kubeconfig is updated.
