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
  az_letters = ["a", "b", "c"]
  zones      = [for i in range(var.availability_zones) : "${local.region}${local.az_letters[i]}"]
}

# Stands in for the VPC ID AWS would generate (vpc-0123456789abcdef0).
resource "random_id" "vpc" {
  byte_length = 8
  keepers = {
    cidr = var.cidr
  }
}

# One fake subnet ID per zone per tier. The CIDRs are real arithmetic on the
# VPC range: /20s, public first, then private.
resource "random_id" "public_subnet" {
  count       = var.availability_zones
  byte_length = 8
}

resource "random_id" "private_subnet" {
  count       = var.availability_zones
  byte_length = 8
}

locals {
  vpc_id  = "vpc-${random_id.vpc.hex}"
  vpc_arn = "arn:aws:ec2:${local.region}:${local.account_id}:vpc/${local.vpc_id}"

  public_subnets = [
    for i, z in local.zones : {
      id                = "subnet-${random_id.public_subnet[i].hex}"
      cidr              = cidrsubnet(var.cidr, 4, i)
      availability_zone = z
    }
  ]
  private_subnets = [
    for i, z in local.zones : {
      id                = "subnet-${random_id.private_subnet[i].hex}"
      cidr              = cidrsubnet(var.cidr, 4, i + 8)
      availability_zone = z
    }
  ]
}
