# Step 9: The API

**Time:** 10 minutes
**Goal:** Create the `api` project with a database, a cache, and an app, and deploy them.
**Behind?** `./catch-up.sh 9`

## 1. Project, environment, three defaults

```bash
mass project create api -n API -d "The API and everything only it uses."
mass environment create api-staging -n Staging
mass resource grant create kubernetes-staging-cluster.cluster --all-environments
mass environment default api-staging "$(mass resource list -t workshop-aws-authentication@~0 -o json | jq -r '.[0].id')"
mass environment default api-staging network-staging-vpc.vpc
mass environment default api-staging kubernetes-staging-cluster.cluster
```

## 2. Add three components

```bash
mass component add api workshop-rds-mariadb --id db --name "App Database"
mass component add api workshop-elasticache-redis --id cache --name "Session Cache"
mass component add api workshop-app --id web --name "Web App"
```

## 3. Link the database and cache to the app

In the UI, drag from the database's output to the app's `database` input, and
from the cache to `cache`. Or:

```bash
mass component link api-db.database api-web.database
mass component link api-cache.cache api-web.cache
```

## 4. Deploy the app first

```bash
cat > /tmp/web.json <<'JSON'
{"image_tag":"latest","replicas":1}
JSON
mass instance deploy api-staging-web -p /tmp/web.json -m "Step 9: too early" --follow
```

Refused before anything runs:

```
required connection "database" is not fulfilled
required connection "cache" is not fulfilled
```

The links exist, but nothing upstream has produced a resource yet.

## 5. Deploy in order

```bash
cat > /tmp/db.json <<'JSON'
{"engine_version":"11.4","instance_class":"db.t4g.micro","allocated_storage_gb":20,"database_name":"app","multi_az":false}
JSON
cat > /tmp/cache.json <<'JSON'
{"node_size":"cache.t4g.micro","num_replicas":0,"encryption_in_transit":true}
JSON
mass instance deploy api-staging-db    -p /tmp/db.json    -m "Step 9: database" --follow &
mass instance deploy api-staging-cache -p /tmp/cache.json -m "Step 9: cache"    --follow &
wait
mass instance deploy api-staging-web -p /tmp/web.json -m "Step 9: now it works" --follow
```

About 90 seconds for the pair, then about a minute for the app. Its log
ends with:

```
cluster_endpoint = "https://<hex>.gr7.us-east-1.eks.amazonaws.com"
database_host    = "api-staging-db-<pet>.workshop.us-east-1.rds.amazonaws.com"
cache_host       = "api-staging-cache-<pet>.workshop.us-east-1.cache.amazonaws.com"
```

## Checkpoint

All three instances in `api-staging` are deployed and the app's log prints the
three hostnames.
