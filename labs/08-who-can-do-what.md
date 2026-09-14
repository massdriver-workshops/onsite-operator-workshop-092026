# Steps 12 and 13: Usage and access control

**Time:** 11 minutes
**Goal:** See where a bundle is used, then invite your teammates, declare attributes, and give each group access by attribute.

## Step 12: Repository usage (2 minutes)

In the UI, open the repository page for **workshop-aws-vpc** and look at where
it is used. Then **workshop-app**.

## Step 13: Attributes and access control (9 minutes)

You work in two orgs: your own as operator, and a teammate's as a member of
one of their groups. The org switcher is at the top left of the UI.

### 1. Invite your two teammates

**Settings → Groups → New group**, twice: `network-team` and `developers`.
Add one teammate to each group by email from the group's **Members** tab.
They receive an invitation to your org and accept it. Tell your team when
yours are sent.

### 2. Declare two attributes

**Settings → Attributes → New**, twice:

| Key | Scope | Values |
|---|---|---|
| `team` | project | `dev`, `ops` |
| `tier` | environment | `prod`, `nonprod` |

### 3. Tag what you have

```bash
mass project update network    -a team=ops
mass project update kubernetes -a team=ops
mass project update api        -a team=dev
mass environment update network-staging    -a tier=nonprod
mass environment update kubernetes-staging -a tier=nonprod
mass environment update api-staging        -a tier=nonprod
```

### 4. Give each group access

`network-team`:

| Effect | Actions | Conditions |
|---|---|---|
| Allow | `project:view`, `project:design`, `environment:create`, `environment:update`, `environment:deploy`, `instance:configure`, `instance:plan`, `instance:deploy`, `resource:view` | `team` = `ops` |

`developers`:

| Effect | Actions | Conditions |
|---|---|---|
| Allow | `project:view`, `project:design`, `repo:view` | `team` = `dev` |
| Allow | `instance:configure`, `instance:plan`, `instance:deploy` | `team` = `dev`, `tier` = `nonprod` |

No row names a project or environment. Both groups' access follows the
attributes: network-team sees the `network` and `kubernetes` projects, and
step 14's production environment is excluded from developers by being tagged
`tier=prod`.

### 5. In a teammate's org, as a developer

- Look at the project list.
- Open **API → staging → Asset Bucket** and deploy it.
- Try to add **workshop-aws-vpc** to the API project.

Tell your teammate what worked.

### 6. In your own org: narrow the VPC grant

```bash
mass repo grant list workshop-aws-vpc
mass repo grant delete <id from the list>
mass repo grant create workshop-aws-vpc --condition team=ops
```

Try it yourself first:

```bash
mass component add api workshop-aws-vpc --id vpc2 --name "Rogue VPC"
```

Refused: the bundle is not granted to this project. Grants apply to the
recipient project regardless of who is acting; an org admin is refused too.
Have your developer teammate try again from the UI.

### 7. In a teammate's org, as network-team

Look at the project list: Network and Kubernetes, not API. Redeploy the VPC.

## Checkpoint

- Both teammates accepted your invitation and sit in one group each.
- `api` is `team=dev`; `network` and `kubernetes` are `team=ops`; all three
  staging environments are `tier=nonprod`.
- Your developer teammate could deploy in `api-staging` and could not add the
  VPC bundle to `api` after the grant was narrowed.
