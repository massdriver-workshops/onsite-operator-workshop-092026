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

  # Databases go in private subnets. This is the VPC contract being read.
  subnet_ids = [for s in var.vpc.infrastructure.private_subnets : s.id]
  identifier = "${var.md_metadata.name_prefix}-${random_pet.instance.id}"
}

resource "random_pet" "instance" {
  length = 2
  keepers = {
    database_name = var.database_name
  }
}

resource "random_password" "master" {
  length  = 32
  special = false
}

locals {
  hostname = "${local.identifier}.workshop.${local.region}.rds.amazonaws.com"
  arn      = "arn:aws:rds:${local.region}:${local.account_id}:db:${local.identifier}"
}
