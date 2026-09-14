# Step 8: The cluster

**Time:** 6 minutes
**Goal:** Create the `kubernetes` project and connect its cluster to the VPC in another project.
**Behind?** `./catch-up.sh 8`

## 1. Project, environment, credential

```bash
mass project create kubernetes -n Kubernetes -d "Shared compute. Owned by the platform team."
mass environment create kubernetes-staging -n Staging
mass environment default kubernetes-staging "$(mass resource list -t workshop-aws-authentication@~0 -o json | jq -r '.[0].id')"
```

## 2. Add the cluster

```bash
mass component add kubernetes workshop-eks-cluster --id cluster --name "Cluster"
```

Open **kubernetes → staging** in the UI and click the cluster. Configure it
with the **Development** preset. It cannot deploy: the required `vpc`
dependency has nothing wired to it. From the CLI the refusal is:

```
required connection "vpc" is not fulfilled
```

## 3. Reference the VPC from the other project

```bash
mass instance remote-reference set kubernetes-staging-cluster vpc network-staging-vpc.vpc
```

Refused: the VPC resource is not granted to this environment. Grant it, then
set the reference:

```bash
mass resource grant create network-staging-vpc.vpc --all-environments
mass instance remote-reference set kubernetes-staging-cluster vpc network-staging-vpc.vpc
```

## 4. Deploy

```bash
cat > /tmp/cluster.json <<'JSON'
{"kubernetes_version":"1.31","node_count":2,"node_size":"t3.medium"}
JSON
mass instance deploy kubernetes-staging-cluster -p /tmp/cluster.json -m "Step 8: cluster" --follow
```

About a minute. The subnet ids in the log came from the VPC resource in the
`network` project.

## 5. Download a kubeconfig

Open the cluster's **Resources** tab and click **Download kubeconfig**. Or:

```bash
mass resource download kubernetes-staging-cluster.cluster -f yaml
```

The format is declared in the resource type under `exports:` and rendered
from `resource-types/workshop-kubernetes-cluster/exports/kubeconfig.yaml.liquid`.
Exports are audit-logged; reads of the resource are not.

## Checkpoint

- `kubernetes-staging-cluster` is deployed.
- Its resource id is `kubernetes-staging-cluster.cluster` and it offers a
  `yaml` download.
