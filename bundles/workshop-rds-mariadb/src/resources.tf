# Publishes the connection details as a `workshop-mariadb` resource.
# This is the worked example for the resources.tf you write in step 10.

resource "massdriver_resource" "database" {
  field = "database"
  name  = "Simulated MariaDB ${local.identifier}"

  resource = jsonencode({
    infrastructure = {
      arn = local.arn
    }
    authentication = {
      hostname = local.hostname
      port     = 3306
      username = "admin"
      password = random_password.master.result
      database = var.database_name
    }
    specs = {
      engine   = "mariadb"
      version  = var.engine_version
      multi_az = var.multi_az
    }
  })
}
