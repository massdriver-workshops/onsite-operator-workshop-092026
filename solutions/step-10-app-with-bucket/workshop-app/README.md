# workshop-app

Simulated for the operator workshop. Provisions no real cloud resources.

The consumer that proves the graph works. It declares **required**
dependencies on three generic resource types: `workshop-kubernetes-cluster`
(an environment default), `workshop-mariadb` and `workshop-redis` (links drawn
on the canvas), plus an **optional** dependency on the AWS credential.

The Terraform is a single `random_id`. The interesting parts of `src/main.tf`
are the reads off the contracts, such as `var.cache.authentication.host`, and
the two `precondition` blocks. In step 9 attendees deploy this app before its
database and cache exist, and those preconditions are what turns a raw
Terraform null error into a sentence that says what to do.

STEP 10.9 SOLUTION: the optional `bucket` dependency on the `workshop-s3-bucket`
type and the `assets_url` output are uncommented, and the version is 0.2.0.
This is how a consumer adopts a contract that did not exist twenty minutes
earlier.

Attendees add it to the `api` project in step 9 as the **Web App**.
