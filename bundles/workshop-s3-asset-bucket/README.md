# workshop-s3-asset-bucket

Simulated for the operator workshop. Provisions no real cloud resources.

The step 10 bundle. It is the first bundle attendees publish themselves, and it
emits the `workshop-s3-bucket` resource type they finish and publish right before it.

It builds and lints clean, but it does not deploy cleanly yet. Debugging it is
the exercise: read the deployment log, find the problem, bump the patch
version, publish a development release, and watch the instance pick it up.
Expect to go around that loop more than once.

It is also deliberately rough as a product. Three untitled fields, no help
text, no defaults, no presets, nothing stopping `-5` retention days. Step 11
fixes the form without touching the Terraform.

## What it provisions

Nothing real. `random_pet` produces a unique bucket suffix and the outputs are
assembled into a `workshop-s3-bucket` resource with an S3-shaped ARN and
endpoint. The region comes from the connected `workshop-aws-authentication`
resource, so you can see dependency data flowing into the provisioner.
