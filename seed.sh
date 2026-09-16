#!/usr/bin/env bash
# seed.sh: publish the workshop's starter resource types and bundles into
# YOUR organization. Run this once at the start of the session (step 5).
#
# Usage:
#   ./seed.sh            publish the starting catalog into your org (step 5)
#   ./seed.sh --check    prework: confirm the CLI, jq, git, your profile, and a
#                        fresh org, then stop. Publishes nothing. Paste the
#                        SUMMARY line into the shared thread.
#
# Uses whatever organization the mass CLI is currently pointed at (your active
# profile from `mass config`). Idempotent: re-running skips anything that is
# already there.
#
# What it does:
#   1. Confirms the CLI authenticates and prints the org.
#   2. Creates an OCI repository for each starter resource type and publishes
#      it: workshop-aws-authentication, workshop-vpc,
#      workshop-kubernetes-cluster, workshop-mariadb, workshop-redis.
#   3. Creates an OCI repository for each starter bundle, grants it to every
#      project in the org (`mass repository grant create --all-projects`),
#      builds it, and publishes it: workshop-aws-vpc, workshop-eks-cluster,
#      workshop-rds-mariadb, workshop-elasticache-redis, workshop-app.
#
# It creates NO projects, environments, or resources. You build those by hand
# during the session. The S3 bucket type and bundle are also left out on
# purpose: you publish those yourself in step 10.
#
# Requires: mass, jq.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESOURCE_TYPES=(workshop-aws-authentication workshop-vpc workshop-kubernetes-cluster workshop-mariadb workshop-redis)
BUNDLES=(workshop-aws-vpc workshop-eks-cluster workshop-rds-mariadb workshop-elasticache-redis workshop-app)

CHECK=0
case "${1:-}" in
  -h|--help) sed -n '2,30p' "$0"; exit 0 ;;
  --check) CHECK=1 ;;
  "") ;;
  *) echo "usage: ./seed.sh [--check]. Point the CLI at your org with 'mass config use <profile>' first." >&2; exit 2 ;;
esac

STEP=""
ORG="?"
log()  { printf '[%s] %s\n' "$STEP" "$*"; }
step() { STEP="$1"; printf '\n=== %s\n' "$STEP"; }
die()  { printf '\nFAILED at step "%s": %s\n' "$STEP" "$*" >&2; exit 1; }
need() { command -v "$1" >/dev/null 2>&1 || die "missing required tool: $1"; }

# Summary bookkeeping.
CREATED=(); SKIPPED=()
created() { CREATED+=("$*"); }
skipped() { SKIPPED+=("$*"); }

need mass; need jq

# ---------------------------------------------------------------------------
step "authenticate"
WHO="$(mass whoami -o json 2>&1)" || die "mass whoami failed. Run 'mass config get' and check your profile.
$WHO"
ORG="$(jq -r '.organization.id // empty' <<<"$WHO")"
[[ -n "$ORG" ]] || die "could not read the organization from 'mass whoami -o json'"
ORG_NAME="$(jq -r '.organization.name // "?"' <<<"$WHO")"
log "org $ORG ($ORG_NAME) as $(jq -r '.name // .email // "?"' <<<"$WHO")"

# ---------------------------------------------------------------------------
if [[ "$CHECK" -eq 1 ]]; then
  step "check"
  FAILS=0
  ok()   { log "PASS  $*"; }
  bad()  { log "FAIL  $*"; FAILS=$((FAILS+1)); }
  note() { log "NOTE  $*"; }
  ok "mass CLI and jq present; profile authenticates against $ORG ($ORG_NAME)"
  if command -v git >/dev/null 2>&1; then ok "git present"; else bad "git present (needed to clone this repo)"; fi
  MISSING=""
  for f in resource-types/workshop-aws-authentication/massdriver.yaml bundles/workshop-aws-vpc/massdriver.yaml bundles/workshop-app/src/main.tf labs ./catch-up.sh; do
    [[ -e "$REPO_ROOT/$f" ]] || MISSING="$MISSING $f"
  done
  if [[ -z "$MISSING" ]]; then ok "workshop repo contents present"; else bad "workshop repo is missing:$MISSING (re-clone the repo)"; fi
  if mass bundle list -o json 2>/dev/null | jq -e '.[]? | select(.name|startswith("workshop-"))' >/dev/null 2>&1; then
    note "org already has workshop bundles. Fine if you ran ./seed.sh before; otherwise tell the facilitator."
  else
    ok "org is fresh (nothing published yet; ./seed.sh does that in the room)"
  fi
  if mass project list -o json 2>/dev/null | jq -e '.[]? | select(.id=="network" or .id=="kubernetes" or .id=="api" or .slug=="network" or .slug=="kubernetes" or .slug=="api")' >/dev/null 2>&1; then
    note "org already has a network, kubernetes, or api project. The session assumes a fresh org; tell the facilitator."
  else
    ok "no workshop projects yet (you create them in the room)"
  fi
  echo
  if [[ "$FAILS" -eq 0 ]]; then
    echo "SUMMARY: READY | org=$ORG ($ORG_NAME) | $(uname -s 2>/dev/null || echo unknown-os) | $(hostname 2>/dev/null || echo unknown-host)"
    exit 0
  else
    echo "SUMMARY: NOT READY | org=$ORG ($ORG_NAME) | $FAILS check(s) failed, see above"
    exit 1
  fi
fi

EXISTING_PROJECTS="$(mass project list -o json 2>/dev/null | jq -r '.[]?.slug // .[]?.id // empty' 2>/dev/null || true)"
if [[ -n "$EXISTING_PROJECTS" ]]; then
  log "WARNING: this org already has projects: $(tr '\n' ' ' <<<"$EXISTING_PROJECTS")"
  log "WARNING: the session assumes a fresh org. Continuing anyway."
fi

# ---------------------------------------------------------------------------
ensure_repo() { # name type
  if mass repository get "$1" >/dev/null 2>&1; then
    log "repository $1 exists"; skipped "repository $1"
  else
    OUT="$(mass repository create "$1" -t "$2" 2>&1)" || die "create repository $1: $OUT"
    log "repository $1 created ($2)"; created "repository $1"
  fi
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
  if has_wildcard_grant "$1"; then
    log "repository $1 already shared with every project"; skipped "grant $1"
  else
    OUT="$(mass repository grant create "$1" --all-projects 2>&1)" || die "grant repository $1: $OUT"
    log "repository $1 shared with every project (repo:pull)"; created "grant $1"
  fi
}

# ---------------------------------------------------------------------------
step "resource types"
for rt in "${RESOURCE_TYPES[@]}"; do
  DIR="$REPO_ROOT/resource-types/$rt"
  [[ -f "$DIR/massdriver.yaml" ]] || die "missing $DIR/massdriver.yaml"
  ensure_repo "$rt" resource-type
  VER="$(grep -m1 '^version:' "$DIR/massdriver.yaml" | awk '{print $2}')"
  if OUT="$(mass resource-type publish "$DIR" 2>&1)"; then
    log "published $rt@$VER"; created "resource type $rt@$VER"
  elif grep -qiE "already (exists|published)" <<<"$OUT"; then
    log "$rt@$VER already published"; skipped "resource type $rt@$VER"
  else
    die "publish resource type $rt: $OUT"
  fi
done

# ---------------------------------------------------------------------------
step "bundles"
for b in "${BUNDLES[@]}"; do
  DIR="$REPO_ROOT/bundles/$b"
  [[ -f "$DIR/massdriver.yaml" ]] || die "missing $DIR/massdriver.yaml"
  ensure_repo "$b" bundle
  ensure_wildcard_grant "$b"
  VER="$(grep -m1 '^version:' "$DIR/massdriver.yaml" | awk '{print $2}')"
  OUT="$(mass bundle build -b "$DIR" 2>&1)" || die "build $b: $OUT"
  if OUT="$(mass bundle publish -b "$DIR" 2>&1)"; then
    log "published $b@$VER"; created "bundle $b@$VER"
  elif grep -qiE "already (exists|published)" <<<"$OUT"; then
    log "$b@$VER already published"; skipped "bundle $b@$VER"
  else
    die "publish bundle $b: $OUT"
  fi
done

# ---------------------------------------------------------------------------
step "summary"
printf '%-16s %s\n' "ORG" "$ORG"
printf '%-16s %s\n' "RESOURCE TYPES" "${RESOURCE_TYPES[*]}"
printf '%-16s %s\n' "BUNDLES" "${BUNDLES[*]}"
printf '%-16s %s\n' "CREATED" "${#CREATED[@]}"
printf '%-16s %s\n' "ALREADY THERE" "${#SKIPPED[@]}"
echo
echo "Not seeded on purpose: projects and environments (steps 7 to 9),"
echo "the credential (step 6), workshop-s3-bucket and workshop-s3-asset-bucket (step 10)."
echo
echo "SEEDED OK"
