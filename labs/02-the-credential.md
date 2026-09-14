# Step 6: The credential

**Time:** 5 minutes
**Goal:** Import a fake AWS credential and share it with every environment.

The credential is fake. Nothing in this workshop touches AWS.

## 1. Read the type

```bash
cat resource-types/workshop-aws-authentication/massdriver.yaml
```

`secret_access_key` is marked `$md.sensitive: true`. `ui.instructions` points
at the markdown the create wizard shows.

## 2. Create the credential

In the UI: **Resources → Create**, choose **Workshop: AWS Authentication
(simulated)**, and follow the instructions the wizard shows.

Or from the CLI:

```bash
cat > /tmp/workshop-credential.json <<'JSON'
{
  "access_key_id": "AKIAWORKSHOPSANDBOX1",
  "secret_access_key": "not-a-real-secret-but-masked-like-one",
  "specs": { "aws": { "region": "us-east-1", "account_alias": "workshop-sandbox" } }
}
JSON
mass resource create -t workshop-aws-authentication@~0 -n "Workshop AWS (simulated)" -f /tmp/workshop-credential.json
```

## 3. Grant it to every environment

Imported resources are addressed by UUID. Without a grant, the credential
cannot be set as an environment default, even by an org admin.

```bash
mass resource grant create "$(mass resource list -t workshop-aws-authentication@~0 -o json | jq -r '.[0].id')" --all-environments
```

Or in the UI: open the resource and add a grant for all environments. Later
steps set this credential as an environment default with the same inline
lookup; in the UI that is the environment's defaults panel.

## Checkpoint

- The resource exists and its secret is masked in the UI.
- `mass resource grant list <uuid>` shows one grant with recipients `everyone`.
