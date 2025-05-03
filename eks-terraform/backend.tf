terraform {
  backend "s3" {
    bucket         = "candidate-6-terraform-state"
    key            = "eks-cluster/terraform.tfstate"
    region         = "us-west-1"
    encrypt        = true
    dynamodb_table = "terraform-lock-table"
  }
}