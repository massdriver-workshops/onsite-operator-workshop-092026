# workshop-elasticache-redis

Simulated for the operator workshop. Provisions no real cloud resources.

A finished producer: sized enum, bounded replica count, presets, and a
`workshop-redis` resource with everything a consumer needs to connect. The auth
token is masked because the resource type says so, not because this bundle
remembered to.

Attendees add it to the `api` project in step 9 as the **Session Cache** and
link it to the Web App. It needs a credential and a VPC; both arrive as
environment defaults, so nobody draws those lines.

The bundle is named for **how** the cache is provisioned (ElastiCache). The
resource type is named for **what** it is (Redis). Swap this for a Valkey
bundle that emits the same type and every consumer keeps working.

Attendees do not edit this bundle.
