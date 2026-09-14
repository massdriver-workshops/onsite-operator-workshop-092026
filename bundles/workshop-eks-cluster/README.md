# workshop-eks-cluster

Simulated for the operator workshop. Provisions no real cloud resources.

Produces a `workshop-kubernetes-cluster` resource: an EKS-shaped ARN, an API
endpoint, a CA bundle, and a bearer token. The last two are masked because the
resource type marks them sensitive.

It requires a VPC, and the VPC lives in a different project. That is the point
of this bundle in the workshop: in step 8 attendees add it to the `kubernetes`
project, discover it cannot deploy, and fill the `vpc` slot with a **remote
reference** to the network project's VPC. The `api` project then receives the
cluster as an environment default in step 9.

Attendees do not edit this bundle.
