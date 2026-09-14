# workshop-s3-asset-bucket, multi-step (advanced track, module B)

The polished step 11 bundle plus a second provisioner step. `src/` is the
bucket. `retention/` is a simulated legal-hold record with `skip_on_delete`,
so decommissioning the bundle tears down the bucket and leaves the record.
The first step also carries a `config.checkov` block whose `halt_on_failure`
is a jq expression that is true only in production.

Version 0.3.0. Publish with `-d` and put the instance on `latest+dev`.
