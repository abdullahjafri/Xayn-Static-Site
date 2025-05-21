# Optional: Terraform remote state backend (S3)
# terraform {
#   backend "s3" {
#     bucket = "your-tf-state-bucket"
#     key    = "xayn/eks/terraform.tfstate"
#     region = "us-west-2"
#   }
# }

provider "aws" {
  region = "us-west-2"
}

# Create a VPC for EKS
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  name    = "xayn-vpc"
  cidr    = "10.0.0.0/16"

  azs             = ["us-west-2a", "us-west-2b", "us-west-2c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true

  tags = {
    Environment = "xayn"
  }
}

# Deploy EKS Cluster
module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  cluster_name    = "xayn-eks"
  cluster_version = "1.27"
  vpc_id          = module.vpc.vpc_id
  subnets         = module.vpc.private_subnets

  enable_irsa     = true
  manage_aws_auth = true

  node_groups = {
    default = {
      desired_capacity = 2
      max_capacity     = 3
      min_capacity     = 1
      instance_types   = ["t3.medium"]

      tags = {
        Name = "xayn-eks-node"
      }
    }
  }

  tags = {
    Environment = "xayn"
  }
}

# Kubernetes Provider for Cluster Interaction
provider "kubernetes" {
  config_path = "~/.kube/config"
}

# Helm Provider for Deploying Charts
provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

# Helm Chart: Traefik Ingress Controller
resource "helm_release" "traefik" {
  name             = "traefik"
  repository       = "https://traefik.github.io/charts"
  chart            = "traefik"
  namespace        = "traefik"
  create_namespace = true
  version          = "24.0.0" # optional specific version
}
