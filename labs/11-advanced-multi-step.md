# Advanced B: Multi-step bundles

**Time:** 12 minutes
**Needs:** step 10 done.
**Finished bundle:** `solutions/advanced-multi-step/workshop-s3-asset-bucket`

A bundle's `steps:` list can have more than one entry. Each step runs in its
own container against its own directory, with the same params and connections.

## B1. A second step

In `bundles/workshop-s3-asset-bucket/massdriver.yaml`, uncomment the step
marked `ADVANCED B1`:

```yaml
  - path: retention
    provisioner: opentofu
    skip_on_delete: true
```

Its Terraform is already in `retention/main.tf`.

```bash
cd bundles/workshop-s3-asset-bucket
mass bundle build
cat retention/_massdriver_variables.tf
```

Set `version: 0.3.0`, then:

```bash
mass bundle publish -d
cd ../..
mass instance version api-staging-assets@latest+dev
```

Watch the deployment: two plans, two applies, and `legal_hold_id` in the
output.

## B2. Step configuration

Uncomment the block marked `ADVANCED B2` under the `src` step:

```yaml
    config:
      checkov:
        enable: true
        halt_on_failure: '.params.md_metadata.default_tags["md-environment"] == "production"'
```

Each `config` value is a `jq` expression over `.params` and `.dependencies`,
evaluated at deploy time. With `halt_on_failure` true, the deploy stops
unless Checkov's report is completely clean; when false, findings are
reported and the deploy continues. Set `version: 0.3.1`, publish `-d`, and
read the Checkov section of the log.

## B3. Decommission

Decommission `api-staging-assets` from the UI. The `src` step is torn down;
the `retention` step is skipped because of `skip_on_delete`.

When you are done, put the instance back:

```bash
mass instance version api-staging-assets@latest
```
