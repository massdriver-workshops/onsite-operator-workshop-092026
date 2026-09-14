# Publishes the fake bucket as a `workshop-s3-bucket` resource.

resource "massdriver_resource" "bucket" {
  field = "bucket"
  name  = "Simulated bucket ${local.label}"

  resource = jsonencode({
    infrastructure = {
      arn  = local.bucket_arn
      name = local.bucket_name
    }
    endpoint = {
      url = local.endpoint
    }
    specs = {
      aws = {
        region = local.region
      }
      versioning_enabled = var.versioning_enabled
    }
  })
}
