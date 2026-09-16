# Publishes the fake bucket as a `workshop-s3-bucket` resource.

resource "massdriver_resource" "bucket" {
  field = "bucket"
  name  = "Simulated bucket ${local.bucket_name}"

  resource = jsonencode({
    infrastructure = {
      arn = local.bucket_arn
      # STEP 10.7, second fix: comment the first line, uncomment the second.
      bucket_name = local.bucket_name
      #name        = local.bucket_name
    }
    endpoint = {
      # STRETCH "break the contract": swap these two lines, publish -d, read the error, swap back.
      url = local.endpoint
      #href = local.endpoint
    }
    specs = {
      aws = {
        region = local.region
      }
      versioning_enabled = var.versioning_enabled
    }
  })
}
