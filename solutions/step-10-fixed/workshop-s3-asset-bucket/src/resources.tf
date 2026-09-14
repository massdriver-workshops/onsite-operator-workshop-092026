# Publishes the fake bucket as a `workshop-s3-bucket` resource.

resource "massdriver_resource" "bucket" {
  field = "bucket"
  name  = "Simulated bucket ${local.bucket_name}"

  resource = jsonencode({
    infrastructure = {
      arn = local.bucket_arn
      # BUG 2 was `bucket_name`. The workshop-s3-bucket contract calls it
      # `name`, and additionalProperties: false means the platform rejects
      # the resource rather than silently accepting an extra key.
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
