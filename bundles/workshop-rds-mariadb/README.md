# workshop-rds-mariadb

Simulated for the operator workshop. Provisions no real cloud resources.

A finished, polished producer. It has a good form, it requires a network and a
credential, and it emits the generic `workshop-mariadb` resource type with the
connection details a consumer needs. The password is masked because the
resource type marks it sensitive.

Attendees add it to the `api` project in step 9 as the **App Database** and
link it to the Web App. Its `src/resources.tf` is the worked example to look
at in step 10 when writing the same thing for the bucket bundle.

The bundle is named for **how** the database is provisioned (RDS). The resource
type is named for **what** it is (MariaDB). Swap this bundle for an Aurora one
and every consumer keeps working.

Attendees do not edit this bundle.
