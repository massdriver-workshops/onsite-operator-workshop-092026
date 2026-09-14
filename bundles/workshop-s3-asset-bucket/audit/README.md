# audit step (ADVANCED C1)

Empty on purpose. The `audit` step in `massdriver.yaml` runs the
`massdrivercloud/provisioner-echo` custom provisioner against this directory. The provisioner
prints what it was given and touches nothing, so there is no IaC here.
Uncomment the step in `massdriver.yaml` to use it.
