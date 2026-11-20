#!/usr/bin/env bash
# This project's suites — one command, deterministic exit code.
# Used by the DataSQRL code agent and by CI.
#
# USAGE
#   ./run-tests.sh [options] [<sub-project> ...]
#
#   <sub-project>       zero or more names, in any order, selecting which suites run.
#                       Give none to run them all. Options may appear before, after or
#                       between the names.
#
#   --compile           compile instead of running tests
#   --test              run tests (the default)
#   --env <name>        which environment's configs to use (default: test).
#   --list-envs         print the environments this project declares, one line
#   --list-subprojects  print the sub-projects this project ships, one line
#   --list-invocations  print what would run and run nothing, one
#                       `SQRL_INVOCATION <sub-project> <verb> -r <root> <config...> -b <name>`
#                       line per suite
#
# An unknown sub-project name, or an environment this project does not declare, is an error
# (exit 2) — never a silent no-op that runs nothing and reports success.
#
set -uo pipefail
# `set -e` (exit on the first error) is not used to allow for more granular error handling.

cd "$(dirname "$0")"

# Where this project sits relative to the compiler's mount root. Inside the code agent the mount
# root is the repository (/workspace), so this project in a subdirectory is reached with the
# prefix the orchestrator exports; fall back to the project directory name when it is not set
# (git is unavailable in the agent container, so we cannot derive it from `git rev-parse`).
P="${SQRL_PACKAGE_PREFIX:-}"
if [ -n "$P" ]; then
  ROOT="${P%/}"
else
  ROOT="simple_transaction_analytics"
fi

# The DataSQRL CLI version the code agent container ships; CI and local runs default to the same
# one so snapshots match. Override with SQRL_VERSION.
SQRL_VERSION="${SQRL_VERSION:-0.11.5}"
# Fallback tag for when that version is not published yet (a release in flight). Resolved once,
# on the first docker invocation, and never inside the code agent — the container has its own CLI.
SQRL_FALLBACK_IMAGE="${SQRL_FALLBACK_IMAGE:-datasqrl/cmd:dev}"
IMAGE=""

resolve_image() {
  [ -n "$IMAGE" ] && return 0
  local want="datasqrl/cmd:${SQRL_VERSION}"
  if docker image inspect "$want" >/dev/null 2>&1 || docker pull -q "$want" >/dev/null 2>&1; then
    IMAGE="$want"
    return 0
  fi
  IMAGE="$SQRL_FALLBACK_IMAGE"
  printf 'warning: datasqrl/cmd:%s is not available; falling back to %s\n' \
    "$SQRL_VERSION" "$IMAGE" >&2
}

# ── EDIT FOR YOUR PROJECT ────────────────────────────────────────────────────
# Two sub-projects share the base config and differ only by run_date (and snapshot folder):
# `spending_insights` (run_date 2026-09-02) and `spending_insights_replay` (run_date 2026-09-05).
ENVS="test"
SUBPROJECTS="spending_insights spending_insights_replay"
# ─────────────────────────────────────────────────────────────────────────────

VERB=test
ENV=test
LIST=""
SELECTED=""
while [ $# -gt 0 ]; do
  case "$1" in
    --compile)   VERB=compile ;;
    --test)      VERB=test ;;
    --env)       ENV="${2:-}"; shift ;;
    --env=*)     ENV="${1#--env=}" ;;
    --list-invocations) LIST=1 ;;
    --list-envs) echo "$ENVS"; exit 0 ;;
    --list-subprojects) echo "$SUBPROJECTS"; exit 0 ;;
    -*)          echo "unknown option: $1" >&2; exit 2 ;;
    *)           SELECTED="$SELECTED $1" ;;
  esac
  shift
done
case " $ENVS " in
  *" $ENV "*) ;;
  *) echo "unknown env '$ENV' — this project declares: $ENVS" >&2; exit 2 ;;
esac

for s in $SELECTED; do
  case " $SUBPROJECTS " in
    *" $s "*) ;;
    *) echo "unknown sub-project '$s' — this project ships: $SUBPROJECTS" >&2; exit 2 ;;
  esac
done

selected() {
  [ -z "$SELECTED" ] && return 0
  case " $SELECTED " in *" $1 "*) return 0 ;; esac
  return 1
}

sqrl() {
  local verb="$1"; shift
  local a missing=0
  for a in "$@"; do
    case "$a" in
      *.json) [ -f "$a" ] || { echo "missing config: $a" >&2; missing=1; } ;;
    esac
  done
  [ "$missing" = 1 ] && return 1
  if [ -n "$LIST" ]; then
    printf 'SQRL_INVOCATION %s %s -r %s %s\n' "$SUITE" "$verb" "$ROOT" "$*"
    return 0
  fi

  if [ -x /opt/agent/cmd.sh ]; then
    /opt/agent/cmd.sh "$verb" -r "$ROOT" "$@"
    return
  fi
  local root
  root="$(git rev-parse --show-toplevel 2>/dev/null)" || root="$PWD"
  resolve_image
  docker run --rm ${TZ:+-e TZ="$TZ"} -v "$root":/workspace \
    "$IMAGE" "$verb" -r "$ROOT" "$@"
}

# ── EDIT FOR YOUR PROJECT (optional): setup ──────────────────────────────────
# [ -n "$LIST" ] || ./scripts/generate-testdata.sh || exit 1
# ─────────────────────────────────────────────────────────────────────────────

# ── EDIT FOR YOUR PROJECT: the suite table ───────────────────────────────────
suite() {
  case "$1/$2" in
    spending_insights/test)         echo "spending_insights-shared-package.json spending_insights-test-package.json" ;;
    spending_insights_replay/test)  echo "spending_insights-shared-package.json spending_insights-replay-test-package.json" ;;
    *) return 1 ;;
  esac
}

# ─────────────────────────────────────────────────────────────────────────────
fail=0
SUITE=""
for sub in $SUBPROJECTS; do
  selected "$sub" || continue
  SUITE="$sub"
  args="$(suite "$sub" "$ENV")" || {
    echo "no '$ENV' configs declared for sub-project '$sub'" >&2
    fail=1
    continue
  }
  # Each sub-project gets a fresh Iceberg warehouse so one run's rows never leak
  # into a sibling's snapshot (the test warehouse lives under the project root).
  [ -n "$LIST" ] || rm -rf sqrl_iceberg_data
  # shellcheck disable=SC2086
  sqrl "$VERB" $args -b "$sub" || fail=1
done

exit $fail
