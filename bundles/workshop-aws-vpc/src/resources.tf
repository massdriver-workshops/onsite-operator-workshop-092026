# Publishes the fake network as a `workshop-vpc` resource.

resource "massdriver_resource" "vpc" {
  field = "vpc"
  name  = "Simulated VPC ${local.vpc_id} (${var.cidr})"

  resource = jsonencode({
    infrastructure = {
      arn             = local.vpc_arn
      id              = local.vpc_id
      cidr            = var.cidr
      private_subnets = local.private_subnets
      public_subnets  = local.public_subnets
    }
    specs = {
      aws = {
        region = local.region
      }
    }
  })
}
