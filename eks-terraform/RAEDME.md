# Learn Terraform - Provision an EKS Cluster

This repository contains Terraform configuration files to provision an Amazon Elastic Kubernetes Service (EKS) cluster on AWS. It is designed as a companion to the [Provision an EKS Cluster tutorial](https://developer.hashicorp.com/terraform/tutorials/kubernetes/eks).

## Features

- **VPC Configuration**: Provisions a Virtual Private Cloud (VPC) with public and private subnets, NAT gateway, and DNS hostnames enabled.
- **EKS Cluster**: Creates an EKS cluster with managed node groups.
- **IAM Roles**: Configures IAM roles for the EBS CSI driver using IRSA (IAM Roles for Service Accounts).
- **Cluster Add-ons**: Includes the Amazon EBS CSI driver as an add-on.

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/downloads) installed.
- AWS credentials configured (e.g., via `~/.aws/credentials` or environment variables).
- An AWS account with permissions to create the required resources.

## Usage

1. Clone this repository:
   ```sh
   git clone https://github.com/candidate-6/my-infra.git
   cd eks-terraform
