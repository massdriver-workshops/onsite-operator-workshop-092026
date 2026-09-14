# Publishes the connection details as a workshop-redis resource. The JSON must
# match the resource type schema exactly (additionalProperties: false), and
# `field` must match the key under `resources:` in massdriver.yaml.

resource "massdriver_resource" "cache" {
  field = "cache"
  name  = "Simulated Redis ${local.cluster_id}"

  resource = jsonencode({
    infrastructure = {
      arn = local.arn
    }
    authentication = {
      host       = local.host
      port       = local.port
      auth_token = local.auth_token
    }
    specs = {
      engine                = "redis"
      version               = "7.1"
      encryption_in_transit = var.encryption_in_transit
    }
  })
}
