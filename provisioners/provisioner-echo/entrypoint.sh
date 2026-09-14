#!/bin/bash
# provisioner-echo: a custom provisioner that provisions nothing.
#
# Follows the contract in
# https://docs.massdriver.cloud/platform-operations/self-hosted/custom-provisioners
# and https://docs.massdriver.cloud/bundle-development/provisioners/overview.
# It prints what a step receives from the platform, masks every string in
# dependencies.json, and exits 0 for plan, provision, and decommission.
set -euo pipefail

workdir="/massdriver"
params_path="$workdir/params.json"
dependencies_path="$workdir/dependencies.json"
config_path="$workdir/config.json"
envs_path="$workdir/envs.json"
secrets_path="$workdir/secrets.json"

# Navigate to the proper bundle directory for this step
cd "$workdir/bundle/$MASSDRIVER_STEP_PATH"

echo "provisioner-echo: action=$MASSDRIVER_DEPLOYMENT_ACTION"
echo "  organization $MASSDRIVER_ORGANIZATION_ID"
echo "  bundle       $MASSDRIVER_BUNDLE_NAME@$MASSDRIVER_BUNDLE_VERSION"
echo "  instance     $MASSDRIVER_INSTANCE_ID"
echo "  deployment   $MASSDRIVER_DEPLOYMENT_ID"
echo "  step path    $MASSDRIVER_STEP_PATH"

show() { # label file
  echo
  echo "--- $1 ($2)"
  if [[ -s "$2" ]]; then jq . "$2"; else echo "(empty)"; fi
}

show "params" "$params_path"
show "config (rendered from the step's jq expressions)" "$config_path"
show "envs" "$envs_path"

# Dependencies carry credentials. Show the shape, mask every string leaf.
echo
echo "--- dependencies ($dependencies_path, string values masked)"
if [[ -s "$dependencies_path" ]]; then
  jq 'walk(if type == "string" then "****" else . end)' "$dependencies_path"
else
  echo "(empty)"
fi

echo
echo "--- secrets: $(jq 'length' "$secrets_path" 2>/dev/null || echo 0) key(s), not shown"

system="$(jq -r '.system // "nothing"' "$config_path" 2>/dev/null || echo nothing)"

case "$MASSDRIVER_DEPLOYMENT_ACTION" in
  plan)         echo; echo "provisioner-echo: plan would register $MASSDRIVER_INSTANCE_ID with $system" ;;
  provision)    echo; echo "provisioner-echo: provision registered $MASSDRIVER_INSTANCE_ID with $system" ;;
  decommission) echo; echo "provisioner-echo: decommission removed $MASSDRIVER_INSTANCE_ID from $system" ;;
  *) echo "provisioner-echo: unknown action $MASSDRIVER_DEPLOYMENT_ACTION" >&2; exit 1 ;;
esac

echo "provisioner-echo: done"
