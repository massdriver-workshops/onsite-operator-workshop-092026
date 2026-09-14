# Step 11: The developer's form

**Time:** 5 minutes, if the room is ahead.
**Goal:** Improve the bucket bundle's form without touching its Terraform.
**Finished file:** `solutions/step-11-polished/workshop-s3-asset-bucket`

## 1. Look at the form

Open the **Asset Bucket** instance in the UI and click **Configure**. Three
fields, no labels, no limits. Type `-5` for retention.

## 2. Uncomment the improvements

Open `bundles/workshop-s3-asset-bucket/massdriver.yaml`. Every improvement is
commented out and marked `STEP 11`: presets under `examples`, titles and
limits on the three params, a new optional `storage_class` param, and the
`ui` block. Remove the leading `# ` from every marked line.

## 3. Publish

Set `version: 0.2.0`, then:

```bash
cd bundles/workshop-s3-asset-bucket
mass bundle build && mass bundle lint && mass bundle publish
cd ../..
```

The instance is on `latest`, so a deployment of `0.2.0` starts on its own.
Open **Configure** again and type `-5` for retention.

## Note on new params

`storage_class` was added with a `default` and not added to `required`. In
the dry run, a version that made it required could no longer be deployed on
existing instances, because their stored params did not include it.

## Stretch

In `src/main.tf`, use `var.storage_class` in the resource name (the finished
bundle does this), set `version: 0.2.1`, and publish.
