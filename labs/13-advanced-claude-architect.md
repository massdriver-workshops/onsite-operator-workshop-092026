# Advanced D: The Claude skill

**Time:** 10 minutes
**Needs:** Step 9 (a deployed `api-staging`). Step 10 helps but is not required.

Every other lab had you write the YAML. This one ships no files. You describe
what you want in plain language, and the Massdriver Claude plugin builds it
against your catalog and wires it into the app you already have running.

## D1. Check the plugin is installed

```bash
claude
```

```
/plugin
```

`massdriver` should be listed. If it is not:

```
/plugin marketplace add massdriver-cloud/claude-plugins
/plugin install massdriver@massdriver
```

The plugin reads the same `mass` credentials you have been using all day, so
it operates on *your* org and sees only the bundles your grants allow.

## D2. Ask for the thing

The API app publishes events and nothing consumes them. Ask for the missing
piece in the words a developer would actually use:

```
/massdriver:architect the API app needs a Kafka event stream to publish
order events to. It should be shared, not owned by the api project, and
the app should require it.
```

Do not feed it a schema, a bundle name, or a resource type name. Work in
`staging`, with the AWS credential from step 6.

## D3. Watch it work

It reads your catalog, projects, environments, and grants, then writes a
resource type and a bundle that satisfy the constraints you gave it,
publishes them, and wires the stream into `api-staging-web`.

## Checkpoint

- A deployed Kafka stream in its own project, and an `api-staging-web` that
  depends on it.
- All of it from one sentence, built against the catalog you spent the day
  building.

## The point

Steps 5 through 14 were you being the operator: you wrote the contract, you
enforced it, you decided who could deploy where. None of that goes away here.
The skill works inside the grants, the resource types, and the projects you
built. A citizen engineer pointing this at an empty org gets nothing useful.
Pointed at the org you spent today building, it gets a governed deploy.
