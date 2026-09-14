# Simulated AWS credential

This credential is **fake**. Nothing you enter here reaches AWS, and nothing
deployed in this workshop touches a real cloud account.

You are walking the same flow an operator uses to hand a real credential to
the platform: create a resource of the credential type, then set it as the
default for the environments that should use it.

## 1. Fill in the form

Use these values. Any plausible-looking values work; these are just easy to
type.

| Field | Value |
|---|---|
| Access Key ID | `AKIAWORKSHOPSANDBOX1` |
| Secret Access Key | `not-a-real-secret-but-masked-like-one` |
| Region | `us-east-1` |
| Account Alias | `workshop-sandbox` |

Notice that the Secret Access Key is masked as you type. The resource **type**
marked it sensitive, so every credential of this type is masked everywhere in
the UI and API, and every export of it is audit-logged.

## 2. Make it the default for your environments

Every workshop bundle declares a dependency on this type. Instead of wiring the
credential to each instance by hand, set it once per environment. You will do
this for each environment as you create it in steps 7, 8, and 9:

```bash
mass environment default <project>-staging "$(mass resource list -t workshop-aws-authentication@~0 -o json | jq -r '.[0].id')"
```

Or, in the UI, open the environment and set it in the defaults panel.

From now on, every instance in that environment that needs an AWS credential
has one, including instances added later.

## What this would look like for real

This type models a static access key pair because it is the simplest thing to
type. With a real cloud you would more likely use an IAM role that the platform
assumes, and this page would tell you how to create that role, what trust
policy to attach, and where to copy the ARN from. Which method your org uses is
a decision the Massdriver admins make once. The platform side is identical
either way: one resource, set as an environment default, consumed by every
bundle that declares the dependency.
