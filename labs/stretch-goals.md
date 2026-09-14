# Stretch goals

For anyone ahead of the room. Each stays inside your own org.

## Promote the whole stack

```bash
mass environment create network-production -n Production -a tier=prod
mass environment default network-production "$(mass resource list -t workshop-aws-authentication@~0 -o json | jq -r '.[0].id')"
mass instance copy network-staging-vpc --to network-production-vpc
mass environment deploy network-production --follow
mass resource grant create network-production-vpc.vpc --all-environments

mass environment create kubernetes-production -n Production -a tier=prod
mass environment default kubernetes-production "$(mass resource list -t workshop-aws-authentication@~0 -o json | jq -r '.[0].id')"
mass instance copy kubernetes-staging-cluster --to kubernetes-production-cluster
mass instance remote-reference set kubernetes-production-cluster vpc network-production-vpc.vpc
mass environment deploy kubernetes-production --follow
mass resource grant create kubernetes-production-cluster.cluster --all-environments

mass environment default api-production network-production-vpc.vpc
mass environment default api-production kubernetes-production-cluster.cluster
mass environment deploy api-production --follow
```

## Break the contract on purpose

In `bundles/workshop-s3-asset-bucket/src/resources.tf`, the `endpoint` block
has a commented `href` line under `url`, marked `STRETCH`. Swap which one is
commented. Bump the version, `mass bundle publish -d`, put the instance on
`latest+dev`, and read the deployment error. Swap them back.

## Add an optional field to the type

Add `storage_class` (string, not required) under `specs` in
`resource-types/workshop-s3-bucket/massdriver.yaml`. Set `version: 0.2.0` and
publish it. Redeploy the bucket and the app.

## Roll back

Open a deployed instance, **History**, pick an earlier deployment, **Roll
back**.

## Decommission in order

Decommission **Web App** in `api-staging`, then try to decommission the cache.
