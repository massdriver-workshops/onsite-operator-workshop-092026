# Step 7: The network

**Time:** 7 minutes
**Goal:** Create the `network` project and deploy the VPC.
**Behind?** `./catch-up.sh 7`

## 1. Project and environment

```bash
mass project create network -n Network -d "Shared network. Owned by the network team."
mass environment create network-staging -n Staging
```

Environment ids are `<project>-<environment>`.

## 2. Set the credential as the environment default

```bash
mass environment default network-staging "$(mass resource list -t workshop-aws-authentication@~0 -o json | jq -r '.[0].id')"
```

## 3. Add the VPC component

In the UI, open the **network** project and drag **workshop-aws-vpc** onto the
canvas. Or:

```bash
mass component add network workshop-aws-vpc --id vpc --name "VPC"
```

The instance in `staging` is `network-staging-vpc`.

## 4. Configure and deploy

In the UI, click the VPC in **staging**, pick the **Development** preset, and
deploy. Or:

```bash
cat > /tmp/vpc.json <<'JSON'
{"cidr":"10.10.0.0/16","availability_zones":2,"nat_gateway":"single"}
JSON
mass instance deploy network-staging-vpc -p /tmp/vpc.json -m "Step 7: first deploy" --follow
```

About 80 seconds. The log shows the plan, the apply, a Checkov evaluation, and
the resource being created.

## Checkpoint

- `network-staging-vpc` is deployed.
- Its **Resources** tab shows a `workshop-vpc` resource. Its id is
  `network-staging-vpc.vpc`.

```bash
mass resource get network-staging-vpc.vpc
```
