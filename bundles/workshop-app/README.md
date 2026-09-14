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

In step 10.8 the app grows a fourth, optional dependency on the
`workshop-s3-bucket` type that attendees author in step 10. The dependency and
its output are already in the files, commented out and marked `STEP 10.8`.
Uncommenting them, bumping the version, and republishing is how a consumer
adopts a contract that did not exist twenty minutes earlier.

Attendees add it to the `api` project in step 9 as the **Web App**.
