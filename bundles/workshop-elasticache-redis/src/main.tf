# Simulated for the operator workshop. Provisions no real cloud resources.

terraform {
  required_version = ">= 1.6"
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "3.7.2"
    }
    # Required to publish the resource back to Massdriver. Not a cloud provider.
    massdriver = {
      source  = "massdriver-cloud/massdriver"
      version = "~> 2.0"
    }
  }
}

# Stands in for the ElastiCache AUTH token.
resource "random_password" "auth_token" {
  length  = 32
  special = false
}

# Stands in for the cluster identifier ElastiCache generates.
resource "random_pet" "cluster" {
  length = 2
  keepers = {
    node_size = var.node_size
  }
}

locals {
  region     = var.aws_authentication.specs.aws.region
  account_id = "123456789012" # Simulated. A real bundle reads the caller identity from the credential.
  cluster_id = "${var.md_metadata.name_prefix}-${random_pet.cluster.id}"

  # Caches go in private subnets. Real ElastiCache would put these in a subnet
  # group; here they only prove the VPC contract is being read.
  subnet_ids = [for s in var.vpc.infrastructure.private_subnets : s.id]

  # These four values are everything a consumer needs. resources.tf publishes
  # them as a workshop-redis resource.
  host       = "${local.cluster_id}.workshop.${local.region}.cache.amazonaws.com"
  port       = 6379
  arn        = "arn:aws:elasticache:${local.region}:${local.account_id}:replicationgroup:${local.cluster_id}"
  auth_token = random_password.auth_token.result
}
