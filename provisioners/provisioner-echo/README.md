# provisioner-echo

A custom provisioner for advanced lab C (`labs/12-advanced-custom-provisioner.md`).
It provisions nothing. It prints the params, the rendered `config.json`, the
envs, and `dependencies.json` with every string masked, then exits 0 for
`plan`, `provision`, and `decommission`.

Built to the contract in
https://docs.massdriver.cloud/platform-operations/self-hosted/custom-provisioners.
Custom provisioners are a self-hosted feature. Provisioner images run only
inside a Massdriver deployment, which places the bundle at
`/massdriver/bundle/<step path>` and the inputs under `/massdriver`.

## Publishing

The lab and the `ADVANCED C1` block in
`bundles/workshop-s3-asset-bucket/massdriver.yaml` reference
`massdrivercloud/provisioner-echo:0.1.0`. To rebuild it:

```bash
cd provisioners/provisioner-echo
docker build -t massdrivercloud/provisioner-echo:0.1.0 .
docker push massdrivercloud/provisioner-echo:0.1.0
```

Test it by publishing a bundle that uses it and deploying in a spare org.

The registry must be reachable from the Massdriver cluster, and the image runs as the default provisioner user (uid 10001).
