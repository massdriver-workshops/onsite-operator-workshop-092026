# Advanced A: Permission patterns

**Time:** 12 minutes
**Needs:** steps 13 and 14 done.

Four more policy shapes on the groups from step 13. Groups and policies are
edited in **Settings → Groups**.

## A1. Propose instead of deploy

Add to `developers`:

| Effect | Actions | Conditions |
|---|---|---|
| Allow | `instance:propose` | `team` = `dev`, `tier` = `prod` |

Have your developer teammate open **API → production → Web App** and deploy.
A proposed deployment is created instead of a running one. Approving it
requires `instance:deploy` on the instance, because approving triggers the
deploy. Create a group `release-managers` with Allow `instance:deploy` where
`tier` = `prod`, add yourself, and approve or reject it from the
instance page.

## A2. A deny policy

Add to `developers`:

| Effect | Actions | Conditions |
|---|---|---|
| Deny | `instance:configure`, `instance:deploy` | `md-component` = `db` |

Have your developer teammate deploy the app, the cache, and the database in
`api-staging`. The database is refused. A deny overrides every allow, and a
condition on `md-component` matches every component with that id across all
environments and projects.

## A3. Grants keyed to an attribute

Step 13 already keyed the VPC repository to `team=ops`. Do the same for the
cluster bundle, then for the VPC resource:

```bash
mass repo grant list workshop-eks-cluster
mass repo grant delete <id>
mass repo grant create workshop-eks-cluster --condition team=ops

mass resource grant list network-staging-vpc.vpc
mass resource grant delete <id>
mass resource grant create network-staging-vpc.vpc --condition tier=nonprod
mass environment default api-production network-staging-vpc.vpc
```

## A4. A cross-cutting group

Create `sre`:

| Effect | Actions | Conditions |
|---|---|---|
| Allow | `project:view` | `*` |
| Allow | `instance:deploy`, `instance:decommission`, `instance:propose`, `environment:deploy` | `tier` = `prod` |

Add a teammate and have them run:

```bash
mass environment deploy api-production --follow
mass environment deploy api-staging --follow
```
