# Publishes the fake cluster as a `workshop-kubernetes-cluster` resource.

resource "massdriver_resource" "cluster" {
  field = "cluster"
  name  = "Simulated EKS cluster ${local.cluster_name}"

  resource = jsonencode({
    infrastructure = {
      arn  = local.arn
      name = local.cluster_name
    }
    authentication = {
      endpoint               = local.endpoint
      cluster_ca_certificate = local.ca_cert
      token                  = local.token
    }
    specs = {
      kubernetes_version = var.kubernetes_version
      aws = {
        region = local.region
      }
    }
  })
}
