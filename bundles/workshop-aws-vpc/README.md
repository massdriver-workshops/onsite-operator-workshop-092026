# workshop-aws-vpc

Simulated for the operator workshop. Provisions no real cloud resources.

Produces a `workshop-vpc` resource: a VPC ID and ARN, a CIDR, and a list of
public and private subnets carved from that CIDR with `cidrsubnet()`. The
subnet IDs are random; the CIDR math is real.

Attendees deploy it in step 7 as the only component of the `network` project's
`staging` environment. Its VPC resource is then consumed twice without anyone
drawing a line: the `kubernetes` project reaches it through a **remote
reference** in step 8, and the `api` project receives it as an **environment
default** in step 9. The developers who own `api` never have to be allowed
into `network` at all.

Attendees do not edit this bundle.
