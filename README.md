# Massdriver Operator Workshop

A 90-minute, hands-on session for **platform operators**: the people who
publish bundles, own resource types, draw project boundaries, and decide who
can deploy where. Every attendee works in their own Massdriver organization on
a throwaway self-hosted instance.

> **Nothing in this repo touches a real cloud.** Every bundle provisions only
> `hashicorp/random` resources and finishes in about a minute. The AWS
> vocabulary (VPCs, EKS, RDS, ElastiCache, S3) is borrowed because it is
> familiar. Every bundle and resource type is prefixed `workshop-` and every
> description starts with *"Simulated for the operator workshop"* so none of it
> gets pulled into a real project by mistake.

## The story

One continuous build. Each step exists because the previous one needed it.

| Step | Handout | You leave with |
|---|---|---|
| 5 | [Seed your org](labs/01-seed-your-org.md) | The starting catalog: five resource types, five bundles, every bundle shared org-wide |
| 6 | [The credential](labs/02-the-credential.md) | A fake AWS credential imported by hand, the way an operator does on day one |
| 7 | [The network](labs/03-the-network.md) | A `network` project with a deployed VPC, and the reason it is its own project |
| 8 | [The cluster](labs/04-the-cluster.md) | A `kubernetes` project whose cluster reaches the VPC through a remote reference |
| 9 | [The API](labs/05-the-api.md) | An `api` project with a database, a cache, and an app wired by links, deployed in the wrong order first |
| 10 | [A new bundle](labs/06-a-new-bundle.md) | A resource type you published, a bundle you published, two deploy failures you debugged on the development channel |
| 11 | [The developer's form](labs/07-the-developers-form.md) | The same bundle with constraints, presets, and help text. Cut line. |
| 12, 13 | [Who uses what, and who may](labs/08-who-can-do-what.md) | Repository usage, two groups, a narrowed grant, an attribute of your own, and the experience of being the blocked developer |
| 14 | [Promote to production](labs/09-promote-to-production.md) | A new `api-production` environment with staging's configuration promoted into it, deployed in one command, and closed to developers without editing a policy |

Finished early? See [stretch goals](labs/stretch-goals.md). Experienced
room? The facilitator can swap in the advanced labs, [A](labs/10-advanced-permissions.md), [B](labs/11-advanced-multi-step.md), [C](labs/12-advanced-custom-provisioner.md), and [D](labs/13-advanced-claude-architect.md):
permission patterns, multi-step bundles, a custom provisioner, and the
Massdriver Claude plugin building a bundle against the catalog you just built.
D ships no files on purpose — it is generated live and thrown away.

## The graph at the end

```
org-level resource                network (network team)        kubernetes (platform team)     api (developers)
┌────────────────────────┐        ┌────────────────────┐         ┌──────────────────────┐        ┌────────────────────────────────┐
│ AWS credential         │──env───│ vpc                │─remote──│ cluster              │──env──▶│ db      workshop-rds-mariadb   │
│ (imported by hand, 6)  │default▶│ workshop-aws-vpc   │ ref   ▶ │ workshop-eks-cluster │default │ cache   workshop-elasticache-… │
└────────────────────────┘   │    └────────────────────┘         └──────────────────────┘        │ assets  workshop-s3-asset-bucket│
                             │              └──────────────env default──────────────────────────▶│ web     workshop-app           │
                             └──────────────────────────────env default──────────────────────────▶│           ▲ db  ▲ cache ▲ assets│
                                                                                                  └────────────────────────────────┘
```

Three ways a resource reaches a consumer, all on this canvas:

- **Environment default.** The credential into every environment, and the VPC
  and cluster into `api`. Set once per environment; every instance that wants
  the type gets it. No line.
- **Remote reference.** The VPC into the cluster. One slot on one instance,
  pointed at a resource from another project.
- **Link.** The database, cache, and bucket into the app. Part of the
  blueprint, drawn on the canvas, materialized per environment.

All three are gated by **grants**. A bundle repository must be granted to a
project before a component can be added from it; a resource must be granted
to an environment before it can be a default or a remote reference. Grants
gate the destination, not the person, and there is no admin bypass.

## Naming: generic types, specific bundles

| Resource type (the *what*) | Bundle (the *how*) |
|---|---|
| `workshop-aws-authentication` | none: imported by hand in step 6, the way real credentials are |
| `workshop-vpc` | `workshop-aws-vpc` |
| `workshop-kubernetes-cluster` | `workshop-eks-cluster` |
| `workshop-mariadb` | `workshop-rds-mariadb` |
| `workshop-redis` | `workshop-elasticache-redis` |
| `workshop-s3-bucket` (in the repo, not seeded; attendees finish and publish it in step 10) | `workshop-s3-asset-bucket` (attendees publish this in step 10) |

A logs bucket, a data-lake bucket, and an asset bucket are three bundles that
emit one type. An Aurora bundle could replace the RDS one and every consumer
would keep working. The type is the interface; the bundle is an implementation.

## Attendee quick start

Do this before the session. Your facilitator sends you the three values the
first command needs.

```bash
# 1. Point the CLI at the sandbox and your personal org. Values are in the prework email.
mass config add workshop --org <your-org-id> --api-key <your-api-key> --url https://api.<sandbox-domain> --use
mass whoami

# 2. Clone this repo and confirm everything works. Publishes nothing.
git clone https://github.com/massdriver-workshops/onsite-operator-workshop-092026.git
cd onsite-operator-workshop-092026
./seed.sh --check
```

Paste the last line it prints into the shared thread.

## Repo layout

```
seed.sh                         Step 5. Attendees run it. Publishes the starting catalog into the active profile's org.
                                `./seed.sh --check` is the prework check: same preconditions, publishes nothing.
catch-up.sh                     Bring your org to the end of step N (6 to 10) if you fall behind.
resource-types/                 Contracts. Published by seed.sh.
  workshop-aws-authentication/  Fake AWS credential; its instructions/ folder is what the credential wizard shows.
  workshop-vpc/                 Generic network contract.
  workshop-kubernetes-cluster/  Generic cluster contract. Its exports/ folder renders a downloadable kubeconfig.
  workshop-mariadb/             Generic database contract. The worked example for step 10.
  workshop-redis/               Generic cache contract.
  workshop-s3-bucket/           Step 10. Not seeded. One block commented out for attendees to finish.
bundles/
  workshop-aws-vpc/             Step 7. Deployed into `network`.
  workshop-eks-cluster/         Step 8. Deployed into `kubernetes`.
  workshop-rds-mariadb/         Step 9. A finished producer to learn from.
  workshop-elasticache-redis/   Step 9. Another finished producer.
  workshop-app/                 Step 9. The consumer. Has a commented block for step 10.8.
  workshop-s3-asset-bucket/     Step 10. Not seeded. Ships with two bugs you will find.
labs/                           One handout per step, stretch goals, and the four advanced labs
solutions/                      Finished state of step 10, 10.8, 11, and the multi-step bundle, plus the finished resource type
provisioners/provisioner-echo/  Custom provisioner image for advanced lab C
```

## Falling behind

There are no checkpoint branches, because most of the state lives in your org
rather than in files. Instead:

```bash
./catch-up.sh 8     # everything through step 8, skipping what already exists
```

Steps 6 through 10 are supported. Steps 11 onward are UI work or a single
command.

## Platform vocabulary used in this repo

| You may have heard | This repo says | Where it lives |
|---|---|---|
| Artifact definition | **Resource type** | `resource-types/<name>/massdriver.yaml`, published with `mass resource-type publish` |
| Artifact | **Resource** | Produced at deploy time by `massdriver_resource` in the bundle's IaC |
| `connections:` / `artifacts:` in `massdriver.yaml` | **`dependencies:` / `resources:`** | Each entry is `resource_type: <name>@<version>` plus `required:` |
| `schema-ui.json` | The **`ui:`** block in `massdriver.yaml` | `schema-ui.json` is generated by `mass bundle build`; never edit it |
| Manifest / package | **Component / instance** | Components are the blueprint; instances are per environment |
| Default artifact | **Environment default** | `mass environment default <env> <resource-id>` |
| Cross-project connection | **Remote reference** | `mass instance remote-reference set <instance> <field> <resource-id>` |
| Bundle visibility | **Repository grant** | `mass repo grant create <name> --all-projects` or `--condition k=v` |

Resource type schemas are flat: `infrastructure`, `authentication`, `endpoint`,
and `specs` sit directly under `properties`. There is no `data` wrapper.

## Local development notes

- `mass bundle build` resolves every `dependencies:` entry against the
  organization your CLI points at. A bundle that depends on
  `workshop-aws-authentication` will not build until that resource type is
  published in your org. `./seed.sh` does that.
- `mass bundle build` writes `schema-*.json` and `src/_massdriver_variables.tf`.
  They are gitignored. Never edit them; never commit them.
- Published stable versions are immutable. Bump `version:` before every stable
  publish. `mass bundle publish -d` publishes a development release, which only
  instances on a `+dev` channel (`latest+dev`, `~0+dev`) pick up.
- The `massdriver-cloud/massdriver` provider appears in every bundle's
  `required_providers`. It is not a cloud provider; it is how a bundle hands a
  resource back to the platform.
