# workshop-s3-asset-bucket

Simulated for the operator workshop. Provisions no real cloud resources.

The step 10 bundle. It is the first bundle attendees publish themselves, and it
emits the `workshop-s3-bucket` resource type they author right before it.

STEP 10 SOLUTION: both bugs fixed. Bug 1 was a wrong path into the credential
contract in `src/main.tf` (`specs.region` instead of `specs.aws.region`); it
failed at plan. Bug 2 was a wrong key in `src/resources.tf` (`bucket_name`
instead of `name`); it failed at apply when the platform validated the emitted
resource against the `workshop-s3-bucket` schema.

It is also deliberately rough as a product. Three untitled fields, no help
text, no defaults, no presets, nothing stopping `-5` retention days. Step 11
fixes the form without touching the Terraform.

## What it provisions

Nothing real. `random_pet` produces a unique bucket suffix and the outputs are
assembled into a `workshop-s3-bucket` resource with an S3-shaped ARN and
endpoint. The region comes from the connected `workshop-aws-authentication`
resource, so you can see dependency data flowing into the provisioner.
