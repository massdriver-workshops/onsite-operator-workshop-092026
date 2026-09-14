# Step 14: Promote to production

**Time:** 5 minutes
**Goal:** Create a production environment, promote staging's configuration into it, and deploy it with one command.

## 1. Create the environment

```bash
mass environment create api-production -n Production -d "Production. Same blueprint as staging." -a tier=prod
```

Open **API → production** in the UI: the same four components, nothing
configured or deployed.

## 2. Set the three defaults

```bash
mass environment default api-production "$(mass resource list -t workshop-aws-authentication@~0 -o json | jq -r '.[0].id')"
mass environment default api-production network-staging-vpc.vpc
mass environment default api-production kubernetes-staging-cluster.cluster
```

## 3. Promote staging's configuration

```bash
mass instance copy api-staging-db     --to api-production-db
mass instance copy api-staging-cache  --to api-production-cache
mass instance copy api-staging-assets --to api-production-assets
mass instance copy api-staging-web    --to api-production-web
```

Each command copies the source instance's params to the destination. Nothing
deploys yet.

## 4. Deploy the environment

```bash
mass environment deploy api-production --follow
```

Instances deploy in dependency order: database, cache, and bucket first, then
the app. About three and a half minutes.

## 5. Have your developer teammate try

In your org, as a developer, open **API → production** and try to deploy
anything. The `developers` policy matches `tier=nonprod`; this environment has
`tier=prod`.

## 6. Compare

```bash
mass environment compare api-staging api-production
```

Then, in the UI, switch the production **App Database** to the **Production**
preset, deploy, and compare again.

## Note

Production is using the staging network and cluster because those are the
resources you set as its defaults. Creating production environments for
`network` and `kubernetes` too is the first stretch goal.
