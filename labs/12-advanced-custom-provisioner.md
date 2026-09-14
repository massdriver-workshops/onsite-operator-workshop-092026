# Advanced C: A custom provisioner

**Time:** 10 minutes
**Needs:** Advanced B.

A provisioner is a container image that follows the contract in
https://docs.massdriver.cloud/platform-operations/self-hosted/custom-provisioners:
the platform places the bundle at `/massdriver/bundle/<step path>`, writes
`params.json`, `dependencies.json`, `config.json`, `envs.json`, and
`secrets.json` under `/massdriver`, and sets the `MASSDRIVER_*` variables,
including a deployment token minted for that run.
Custom provisioners are a self-hosted feature, and this sandbox is
self-hosted. `massdrivercloud/provisioner-echo` prints what it receives and
provisions nothing. Its source is `provisioners/provisioner-echo/`.

## C1. Add it as a step

In `bundles/workshop-s3-asset-bucket/massdriver.yaml`, uncomment the step
marked `ADVANCED C1`:

```yaml
  - path: audit
    provisioner: massdrivercloud/provisioner-echo:0.1.0
    config:
      system: '@text "cmdb"'
      region: .dependencies.aws_authentication.specs.aws.region
      owner: .params.md_metadata.name_prefix
```

The `audit/` directory already exists.

Set the version, publish `-d`, and read the third container's section of the
deployment log.

## C2. Read the source

```bash
cat provisioners/provisioner-echo/entrypoint.sh
```

The script reads the files under `/massdriver`, masks every string in
`dependencies.json`, and branches on `MASSDRIVER_DEPLOYMENT_ACTION`.
