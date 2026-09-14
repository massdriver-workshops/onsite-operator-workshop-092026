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

# Bucket names are globally unique, so real bundles append a random suffix.
# `keepers` means changing bucket_name produces a new suffix (a new bucket),
# while every other change leaves it alone.
resource "random_pet" "suffix" {
  length = 2
  keepers = {
    bucket_name = var.bucket_name
  }
}

# Fake component that would normally come from the cloud API. Here just to
# make the ARN look like it has a real identifier in it.
resource "random_string" "arn_component" {
  length  = 8
  upper   = false
  special = false
}

locals {
  # Region flows in from the connected credential. BUG 1 was `specs.region`;
  # the workshop-aws-authentication contract nests it under `specs.aws`.
  region      = var.aws_authentication.specs.aws.region
  bucket_name = "${var.bucket_name}-${random_pet.suffix.id}-${random_string.arn_component.result}"
  bucket_arn  = "arn:aws:s3:::${local.bucket_name}"
  endpoint    = "https://${local.bucket_name}.s3.${local.region}.amazonaws.com"
}
