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

locals {
  region     = var.aws_authentication.specs.aws.region
  account_id = "123456789012" # Simulated. A real bundle reads the caller identity from the credential.

  # Worker nodes go in private subnets. This is the VPC contract being read,
  # and it arrived through a remote reference from another project.
  subnet_ids   = [for s in var.vpc.infrastructure.private_subnets : s.id]
  cluster_name = "${var.md_metadata.name_prefix}-${random_pet.cluster.id}"
}

# Stands in for the cluster identifier.
resource "random_pet" "cluster" {
  length = 2
  keepers = {
    kubernetes_version = var.kubernetes_version
  }
}

# Stands in for the service-account bearer token.
resource "random_password" "token" {
  length  = 40
  special = false
}

# Stands in for the cluster CA bundle.
resource "random_id" "ca" {
  byte_length = 32
}

# Stands in for the endpoint hash EKS generates.
resource "random_id" "endpoint" {
  byte_length = 16
}

locals {
  arn      = "arn:aws:eks:${local.region}:${local.account_id}:cluster/${local.cluster_name}"
  endpoint = "https://${upper(random_id.endpoint.hex)}.gr7.${local.region}.eks.amazonaws.com"
  ca_cert  = random_id.ca.b64_std
  token    = random_password.token.result
}
