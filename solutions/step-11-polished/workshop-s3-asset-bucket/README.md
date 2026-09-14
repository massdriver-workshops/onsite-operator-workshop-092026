# workshop-s3-asset-bucket

Simulated for the operator workshop. Provisions no real cloud resources.

STEP 11 SOLUTION. Both step 10 bugs are fixed and the form is finished:
titles, help text, constraints enforced in the form and at the API, a
`storage_class` dropdown with readable labels, Development and Production
presets, and a field order that puts the important decision first. The
Terraform changed by one line, to show the new param in the resource name.

## What it provisions

Nothing real. `random_pet` produces a unique bucket suffix and the outputs are
assembled into a `workshop-s3-bucket` resource with an S3-shaped ARN and
endpoint. The region comes from the connected `workshop-aws-authentication`
resource, so you can see dependency data flowing into the provisioner.
