#!/usr/bin/env bash
# catch-up.sh: bring YOUR org to the end of a given step, so you can rejoin
# the session if you fall behind. Runs the same commands the handouts do.
#
# Usage:
#   ./catch-up.sh <step>                  step is 6, 7, 8, 9, or 10
#
# Performs every step up to and including <step>, skipping anything that
# already exists. Uses whatever organization the mass CLI is pointed at (your
# active profile). Assumes ./seed.sh has already run.
#
#   6   import the fake AWS credential
#   7   project network + staging, credential default, deploy the VPC
#   8   project kubernetes + staging, credential default, cluster component,
#       remote reference to the network's VPC, deploy the cluster
#   9   project api + staging, defaults (credential, VPC, cluster), components
#       db / cache / web, links, deploy db and cache then web
#  10   publish the workshop-s3-bucket resource type and the FIXED
#       workshop-s3-asset-bucket bundle from solutions/, share the
#       repository with every project, add the assets component, deploy it
#
# Requires: mass, jq.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOLUTIONS="$REPO_ROOT/solutions"

TARGET="${1:-}"
case "$TARGET" in
  -h|--help|"") sed -n '2,23p' "$0"; [[ -z "$TARGET" ]] && exit 2; exit 0 ;;
  6|7|8|9|10) ;;
  *) echo "step must be one of 6, 7, 8, 9, 10 (got '$TARGET')" >&2; exit 2 ;;
esac

STEP=""
log()  { printf '[step %s] %s\n' "$STEP" "$*"; }
step() { STEP="$1"; printf '\n=== step %s: %s\n' "$1" "$2"; }
die()  { printf '\nFAILED in step %s: %s\n' "$STEP" "$*" >&2; exit 1; }
need() { command -v "$1" >/dev/null 2>&1 || die "missing required tool: $1"; }
need mass; need jq

CREATED=(); SKIPPED=()
created() { CREATED+=("$*"); log "created: $*"; }
skipped() { SKIPPED+=("$*"); log "exists:  $*"; }

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

# ---------------------------------------------------------------------------
# helpers, all idempotent
# ---------------------------------------------------------------------------
ensure_project() { # slug name description
  if mass project get "$1" >/dev/null 2>&1; then skipped "project $1"; else
    OUT="$(mass project create "$1" -n "$2" -d "$3" 2>&1)" || die "project create $1: $OUT"; created "project $1"; fi
}
ensure_environment() { # id name
  if mass environment get "$1" >/dev/null 2>&1; then skipped "environment $1"; else
    OUT="$(mass environment create "$1" -n "$2" 2>&1)" || die "environment create $1: $OUT"; created "environment $1"; fi
}
# Environment defaults cannot be listed reliably from the CLI, so setting one
# again is the idempotent path; the server replaces the default for that type.
ensure_resource_grant() { # resource-id
  # Resources are private to where they were created until granted; even the
  # org admin cannot set an ungranted resource as a default or remote reference.
  if mass resource grant list "$1" 2>/dev/null | grep -qi 'everyone'; then skipped "resource grant $1 (every environment)"; return; fi
  OUT="$(mass resource grant create "$1" --all-environments 2>&1)" || die "resource grant create $1: $OUT"; created "resource grant $1 (every environment)"
}
ensure_default() { # env resource-id
  OUT="$(mass environment default "$1" "$2" 2>&1)" || die "environment default $1 $2: $OUT"
  log "default on $1: $2"
}
ensure_component() { # project bundle id name
  local pj
  pj="$(mass project get "$1" -o json 2>&1)" || die "project get $1: $pj"
  if jq -e --arg id "$1-$3" --arg short "$3" '.components[]? | select(.id==$id or .id==$short or .slug==$short)' <<<"$pj" >/dev/null 2>&1; then
    skipped "component $1/$3"
  else
    OUT="$(mass component add "$1" "$2" --id "$3" --name "$4" 2>&1)" || die "component add $1/$3: $OUT"; created "component $1/$3 ($2)"
  fi
}
link_exists() { # project from(component.field) to(component.field)
  local pj fc ff tc tf
  fc="${2%.*}"; ff="${2##*.}"; tc="${3%.*}"; tf="${3##*.}"
  pj="$(mass project get "$1" -o json 2>/dev/null)" || return 1
  jq -e --arg fc "$fc" --arg ff "$ff" --arg tc "$tc" --arg tf "$tf" \
    '.links[]? | select(.fromComponent.id==$fc and .fromField==$ff and .toComponent.id==$tc and .toField==$tf)' <<<"$pj" >/dev/null 2>&1
}
ensure_link() { # project from to
  # The server accepts duplicate links, so check the blueprint first.
  if link_exists "$1" "$2" "$3"; then skipped "link $2 -> $3"; return; fi
  if OUT="$(mass component link "$2" "$3" 2>&1)"; then created "link $2 -> $3"
  else die "component link $2 $3: $OUT"; fi
}
instance_status() { mass instance get "$1" -o json 2>/dev/null | jq -r '.status // "MISSING"' | tr '[:lower:]' '[:upper:]'; }
ensure_deployed() { # instance params-file message
  local st; st="$(instance_status "$1")"
  if [[ "$st" == PROVISIONED ]]; then skipped "instance $1 deployed"; return; fi
  log "deploying $1 (was $st)"
  mass instance deploy "$1" -p "$2" -m "$3" --follow || die "deploy $1 failed; read the log above"
  created "instance $1 deployed"
}
ensure_repo() { # name type
  if mass repository get "$1" >/dev/null 2>&1; then skipped "repository $1"; else
    OUT="$(mass repository create "$1" -t "$2" 2>&1)" || die "repository create $1: $OUT"; created "repository $1"; fi
}
has_wildcard_grant() { # repo name
  # `grant list -o json` does not include the recipient conditions on this
  # CLI build, so read the table, where an org-wide grant shows as "everyone".
  local text json
  text="$(mass repository grant list "$1" 2>/dev/null || true)"
  if grep -qi 'everyone' <<<"$text"; then return 0; fi
  if json="$(mass repository grant list "$1" -o json 2>/dev/null)" && jq -e . <<<"$json" >/dev/null 2>&1; then
    jq -e '[ .. | objects
             | (.recipientConditions // .recipient_conditions // .recipients // empty)
             | tostring | ascii_downcase
             | select(. == "*" or . == "\"*\"" or . == "everyone" or . == "null") ] | length > 0' <<<"$json" >/dev/null 2>&1
    return
  fi
  return 1
}
ensure_wildcard_grant() { # name
  if has_wildcard_grant "$1"; then skipped "grant $1 (every project)"; else
    OUT="$(mass repository grant create "$1" --all-projects 2>&1)" || die "repository grant create $1: $OUT"; created "grant $1 (every project)"; fi
}

# ---------------------------------------------------------------------------
WHO="$(mass whoami -o json 2>&1)" || die "mass whoami failed. Run 'mass config get' and check your profile.
$WHO"
ORG="$(jq -r '.organization.id // "?"' <<<"$WHO")"
echo "Catching up org $ORG through step $TARGET."

# ---------------------------------------------------------------------------
step 6 "the credential"
CRED="$(mass resource list -t workshop-aws-authentication@~0 -o json 2>/dev/null | jq -r '.[0].id // empty' 2>/dev/null || true)"
if [[ -n "$CRED" ]]; then
  skipped "credential $CRED"
else
  cat > "$TMP/workshop-credential.json" <<'JSON'
{
  "access_key_id": "AKIAWORKSHOPSANDBOX1",
  "secret_access_key": "not-a-real-secret-but-masked-like-one",
  "specs": { "aws": { "region": "us-east-1", "account_alias": "workshop-sandbox" } }
}
JSON
  OUT="$(mass resource create -t workshop-aws-authentication@~0 -n "Workshop AWS (simulated)" -f "$TMP/workshop-credential.json" 2>&1)" || die "resource create: $OUT"
  CRED="$(mass resource list -t workshop-aws-authentication@~0 -o json | jq -r '.[0].id // empty')"
  [[ -n "$CRED" ]] || die "credential created but not found in 'mass resource list'"
  created "credential $CRED"
fi
ensure_resource_grant "$CRED"
[[ "$TARGET" -ge 7 ]] || { echo; echo "Done through step 6."; exit 0; }

# ---------------------------------------------------------------------------
step 7 "the network"
ensure_project network Network "Shared network. Owned by the network team."
ensure_environment network-staging Staging
ensure_default network-staging "$CRED"
ensure_component network workshop-aws-vpc vpc "VPC"
echo '{"cidr":"10.10.0.0/16","availability_zones":2,"nat_gateway":"single"}' >"$TMP/vpc.json"
ensure_deployed network-staging-vpc "$TMP/vpc.json" "Step 7: first deploy"
ensure_resource_grant network-staging-vpc.vpc
[[ "$TARGET" -ge 8 ]] || { echo; echo "Done through step 7."; exit 0; }

# ---------------------------------------------------------------------------
step 8 "the cluster"
ensure_project kubernetes Kubernetes "Shared compute. Owned by the platform team."
ensure_environment kubernetes-staging Staging
ensure_default kubernetes-staging "$CRED"
ensure_component kubernetes workshop-eks-cluster cluster "Cluster"
if [[ "$(instance_status kubernetes-staging-cluster)" == PROVISIONED ]]; then
  skipped "remote reference kubernetes-staging-cluster.vpc (instance already deployed)"
else
  OUT="$(mass instance remote-reference set kubernetes-staging-cluster vpc network-staging-vpc.vpc 2>&1)" || die "remote-reference set: $OUT"
  created "remote reference kubernetes-staging-cluster.vpc -> network-staging-vpc.vpc"
fi
echo '{"kubernetes_version":"1.31","node_count":2,"node_size":"t3.medium"}' >"$TMP/cluster.json"
ensure_deployed kubernetes-staging-cluster "$TMP/cluster.json" "Step 8: cluster"
ensure_resource_grant kubernetes-staging-cluster.cluster
[[ "$TARGET" -ge 9 ]] || { echo; echo "Done through step 8."; exit 0; }

# ---------------------------------------------------------------------------
step 9 "the api"
ensure_project api API "The application. Owned by developers."
ensure_environment api-staging Staging
ensure_default api-staging "$CRED"
ensure_default api-staging network-staging-vpc.vpc
ensure_default api-staging kubernetes-staging-cluster.cluster
ensure_component api workshop-rds-mariadb db "App Database"
ensure_component api workshop-elasticache-redis cache "Session Cache"
ensure_component api workshop-app web "Web App"
ensure_link api api-db.database api-web.database
ensure_link api api-cache.cache api-web.cache
echo '{"engine_version":"11.4","instance_class":"db.t4g.micro","allocated_storage_gb":20,"database_name":"app","multi_az":false}' >"$TMP/db.json"
echo '{"node_size":"cache.t4g.micro","num_replicas":0,"encryption_in_transit":true}' >"$TMP/cache.json"
echo '{"image_tag":"latest","replicas":1}' >"$TMP/web.json"
# The handout deploys web first on purpose to show the failure. Here we go in
# dependency order so the catch-up is green.
ensure_deployed api-staging-db "$TMP/db.json" "Step 9: database"
ensure_deployed api-staging-cache "$TMP/cache.json" "Step 9: cache"
ensure_deployed api-staging-web "$TMP/web.json" "Step 9: web app"
[[ "$TARGET" -ge 10 ]] || { echo; echo "Done through step 9."; exit 0; }

# ---------------------------------------------------------------------------
step 10 "a new bundle (from the solutions)"
TYPE_DIR="$SOLUTIONS/workshop-s3-bucket"
BUNDLE_DIR="$SOLUTIONS/step-10-fixed/workshop-s3-asset-bucket"
[[ -f "$TYPE_DIR/massdriver.yaml" ]] || die "missing $TYPE_DIR/massdriver.yaml"
[[ -f "$BUNDLE_DIR/massdriver.yaml" ]] || die "missing $BUNDLE_DIR/massdriver.yaml"

ensure_repo workshop-s3-bucket resource-type
if OUT="$(mass resource-type publish "$TYPE_DIR" 2>&1)"; then created "resource type workshop-s3-bucket"
elif grep -qiE "already (exists|published)" <<<"$OUT"; then skipped "resource type workshop-s3-bucket"
else die "resource-type publish: $OUT"; fi

ensure_repo workshop-s3-asset-bucket bundle
ensure_wildcard_grant workshop-s3-asset-bucket
VER="$(grep -m1 '^version:' "$BUNDLE_DIR/massdriver.yaml" | awk '{print $2}')"
OUT="$(mass bundle build -b "$BUNDLE_DIR" 2>&1)" || die "bundle build: $OUT"
if OUT="$(mass bundle publish -b "$BUNDLE_DIR" 2>&1)"; then created "bundle workshop-s3-asset-bucket@$VER"
elif grep -qiE "already (exists|published)" <<<"$OUT"; then skipped "bundle workshop-s3-asset-bucket@$VER"
else die "bundle publish: $OUT"; fi

ensure_component api workshop-s3-asset-bucket assets "Asset Bucket"
OUT="$(mass instance version "api-staging-assets@latest" 2>&1)" || log "note: could not set release channel: $OUT"
echo '{"bucket_name":"assets","versioning_enabled":true,"retention_days":30}' >"$TMP/assets.json"
ensure_deployed api-staging-assets "$TMP/assets.json" "Step 10: asset bucket (fixed)"

# ---------------------------------------------------------------------------
echo
echo "=== summary (org $ORG, through step $TARGET)"
printf 'created (%d):\n' "${#CREATED[@]}"; for c in "${CREATED[@]}"; do printf '  + %s\n' "$c"; done
printf 'already there (%d):\n' "${#SKIPPED[@]}"; for s in "${SKIPPED[@]}"; do printf '  = %s\n' "$s"; done
echo
echo "Done through step $TARGET."
