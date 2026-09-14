# Step 10: A new bundle

**Time:** 22 minutes
**Goal:** Publish a resource type and a bundle, share the bundle, then fix it on the development channel.
**Behind?** `./catch-up.sh 10`. Finished files are in `solutions/`.

## 1. Finish the resource type

```bash
cat resource-types/workshop-s3-bucket/massdriver.yaml
```

The `specs` block and its entry under `required` are commented out. Remove
the leading `# ` from every line marked `STEP 10.1`. Nothing else changes.
`solutions/workshop-s3-bucket/massdriver.yaml` is the finished
file.

## 2. Create the two repositories and publish the type

```bash
mass repo create workshop-s3-bucket -t resource-type
mass repo create workshop-s3-asset-bucket -t bundle
mass resource-type publish resource-types/workshop-s3-bucket
mass resource-type get workshop-s3-bucket
```

Resource types have no development channel; every publish is a version.

## 3. Publish the bundle

```bash
cd bundles/workshop-s3-asset-bucket
mass bundle build && mass bundle lint && mass bundle publish
cd ../..
```

## 4. Try to use it

In the UI, open **API → staging** and drag **workshop-s3-asset-bucket** onto
the canvas. Or:

```bash
mass component add api workshop-s3-asset-bucket --id assets --name "Asset Bucket"
```

Refused: the bundle is not granted to this project. A new repository is
private until it is shared. Share it, then add it:

```bash
mass repo grant create workshop-s3-asset-bucket --all-projects
mass component add api workshop-s3-asset-bucket --id assets --name "Asset Bucket"
```

## 5. Deploy it

```bash
cat > /tmp/assets.json <<'JSON'
{"bucket_name":"assets","versioning_enabled":true,"retention_days":30}
JSON
mass instance deploy api-staging-assets -p /tmp/assets.json -m "Step 10: first attempt" --follow
```

It fails at plan with `Unsupported attribute` on `main.tf` line 38.

## 6. Switch the instance to development releases

```bash
mass instance version api-staging-assets@latest+dev
```

A new instance is pinned to the bundle version current when its component was
added. On `latest+dev` it follows every `mass bundle publish -d`.

## 7. First fix

In `src/main.tf` the fix is the commented line under the broken one, marked
`STEP 10.6`. Comment the broken line, uncomment the fix. Set
`version: 0.1.1`. Then:

```bash
cd bundles/workshop-s3-asset-bucket
mass bundle build && mass bundle publish -d
cd ../..
```

A deployment starts on its own within a few seconds. It fails at apply:

```
create resource: 422: payload: infrastructure.bucket_name Schema does not allow additional properties., infrastructure Required property name was not present.
```

If the error also mentions `specs`, step 1 was skipped. Fix the type, set its
version to `0.1.1`, publish it, and change the bundle's `resources:` entry to
`workshop-s3-bucket@0.1.1`.

## 8. Second fix

Same move in `src/resources.tf`, marked `STEP 10.6`. Set `version: 0.1.2`.
Publish `-d` again. The deployment completes.

## 9. Publish stable and return to the stable channel

```bash
cd bundles/workshop-s3-asset-bucket
mass bundle publish
cd ../..
mass instance version api-staging-assets@latest
```

Changing the channel triggers one more deployment, of the stable `0.1.2`.

## 10. If time holds: let the app use the bucket

In `bundles/workshop-app/massdriver.yaml` and `bundles/workshop-app/src/main.tf`,
uncomment the blocks marked `STEP 10.8`. Set the app's `version: 0.2.0`. Then:

```bash
cd bundles/workshop-app
mass bundle build && mass bundle publish
cd ../..
mass instance version api-staging-web@latest
mass component link api-assets.bucket api-web.bucket
mass instance deploy api-staging-web -m "Step 10: consume the bucket" --follow
```

The log prints `assets_url`.

## Checkpoint

- `mass resource-type get workshop-s3-bucket` shows version 0.1.0.
- `api-staging-assets` is deployed on stable `0.1.2`.
- Its **Resources** tab shows a `workshop-s3-bucket` resource.
