# Simulated for the operator workshop. Provisions no real cloud resources.
#
# Second step of the bundle. Stands in for a legal-hold or backup-vault record
# that must outlive the bucket. `skip_on_delete: true` in massdriver.yaml means
# decommissioning the bundle leaves this step's state in place.

terraform {
  required_version = ">= 1.6"
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "3.7.2"
    }
  }
}

# Every step receives the same params and connections, so retention_days is
# available here without any wiring.
resource "random_uuid" "legal_hold" {
  keepers = {
    retention_days = tostring(var.retention_days)
  }
}

output "legal_hold_id" {
  value = random_uuid.legal_hold.result
}
