# Step 5: Seed your organization

**Time:** 4 minutes
**Goal:** Publish the starting catalog into your org.

## 1. Confirm the CLI points at your org

```bash
mass whoami
```

## 2. Run the seed

```bash
./seed.sh
```

About a minute. For each item it creates a repository, publishes into it, and
grants the bundle repositories to every project in the org.

## 3. Check

```bash
mass bundle list
mass resource-type list
```

Five bundles, five resource types. Not seeded on purpose: the
`workshop-s3-bucket` resource type and the `workshop-s3-asset-bucket` bundle.
You publish those in step 10.

If a count is off, run `./seed.sh` again. It skips what already exists.
