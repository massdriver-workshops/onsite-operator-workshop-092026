# Simulated for the operator workshop. Provisions no real cloud resources.

terraform {
  required_version = ">= 1.6"
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "3.7.2"
    }
    # Kept for parity with the other bundles; this bundle emits no resources.
    massdriver = {
      source  = "massdriver-cloud/massdriver"
      version = "~> 2.0"
    }
  }
}

locals {
  # Dependency data, read off the contracts. A linked dependency whose
  # producer has not deployed yet arrives empty, so every read is wrapped in
  # try() and the preconditions below turn "empty" into a readable error.
  db_host     = try(var.database.authentication.hostname, "")
  db_port     = try(var.database.authentication.port, 3306)
  db_user     = try(var.database.authentication.username, "")
  db_pass     = try(var.database.authentication.password, "")
  db_name     = try(var.database.authentication.database, "")
  cache_host  = try(var.cache.authentication.host, "")
  cache_port  = try(var.cache.authentication.port, 6379)
  cache_token = try(var.cache.authentication.auth_token, "")
  cache_tls   = try(var.cache.specs.encryption_in_transit, false)

  # The cluster is an environment default, so it is always present.
  cluster_endpoint = var.kubernetes_cluster.authentication.endpoint
  cluster_name     = var.kubernetes_cluster.infrastructure.name

  # Optional dependency: null when nothing is connected.
  aws_region = try(var.aws_authentication.specs.aws.region, "not-connected")

  # STEP 10.8: uncomment to consume the bucket
  # assets_url = try(var.bucket.endpoint.url, "no bucket connected")
}

# Stands in for a deployment identifier.
resource "random_id" "deployment" {
  byte_length = 4
  keepers = {
    image_tag = var.image_tag
    replicas  = tostring(var.replicas)
  }

  # A bundle author decides what a failed dependency looks like to the person
  # deploying. Without these, the error is a raw null-attribute message from
  # Terraform. With them, it says what to do.
  lifecycle {
    precondition {
      condition     = try(var.database.authentication.hostname, "") != ""
      error_message = "The database dependency has no resource yet. Deploy the App Database instance first, then redeploy the Web App."
    }
    precondition {
      condition     = try(var.cache.authentication.host, "") != ""
      error_message = "The cache dependency has no resource yet. Deploy the Session Cache instance first, then redeploy the Web App."
    }
  }
}

locals {
  app_name     = "${var.md_metadata.name_prefix}-${random_id.deployment.hex}"
  cache_scheme = local.cache_tls ? "rediss" : "redis"
  cache_url    = "${local.cache_scheme}://:${local.cache_token}@${local.cache_host}:${local.cache_port}"
  database_url = "mysql://${local.db_user}:${local.db_pass}@${local.db_host}:${local.db_port}/${local.db_name}"
}

# Outputs are visible in the deployment log, which is how attendees see the
# connections resolved without any real infrastructure to inspect.
output "app_name" {
  value = local.app_name
}

output "cluster_endpoint" {
  value = local.cluster_endpoint
}

output "database_host" {
  value = local.db_host
}

output "cache_host" {
  value = local.cache_host
}

# STEP 10.8: uncomment to consume the bucket
# output "assets_url" {
#   value = local.assets_url
# }

output "aws_region" {
  value = local.aws_region
}

output "cache_url" {
  value     = local.cache_url
  sensitive = true
}

output "database_url" {
  value     = local.database_url
  sensitive = true
}
