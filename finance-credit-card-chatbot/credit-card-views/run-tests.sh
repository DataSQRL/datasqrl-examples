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
#                       `--env=<name>` is accepted too.
#   --list-envs         print the environments this project declares, one line
#   --list-subprojects  print the sub-projects this project ships, one line
#   --list-invocations  print what would run and run nothing, one
#                       `SQRL_INVOCATION <sub-project> <verb> -r <root> <config...> -b <dir>`
#                       line per suite — exactly the arguments a real run would use
#
# EXAMPLES (using this project's own sub-project, creditcard_views)
#   ./run-tests.sh                                              test every suite, env test
#   ./run-tests.sh creditcard_views                         test just that sub-project
#   ./run-tests.sh --compile --env prod                         compile every suite as prod
#   ./run-tests.sh --compile --env prod creditcard_views    compile just that one, as prod
#   ./run-tests.sh --list-invocations --compile --env prod      show what would run
#
#   A project with several sub-projects names as many as it likes:
#   ./run-tests.sh <sub-project> <sub-project>
#
# An unknown sub-project name, or an environment this project does not declare, is an error
# (exit 2) — never a silent no-op that runs nothing and reports success.
#
# WRITING THIS FILE FOR A PROJECT
#   Three blocks below are marked "EDIT FOR YOUR PROJECT": the ENVS/SUBPROJECTS declarations,
#   the `suite` table, and the optional setup/teardown hooks. Everything else is boilerplate —
#   copy it verbatim.
#
#   The `suite` table is the ONE place a project's config layering is written down: for each
#   sub-project and each environment, the exact configs to layer, in merge order.
#
set -uo pipefail
# `set -e` (exit on the first error) is not used to allow for more granular error handling.

cd "$(dirname "$0")"

# Where this project sits relative to the compiler's mount root. Inside the code agent the mount
# root is the repository, so a project in a subdirectory is reached with the prefix the
# orchestrator exports; empty everywhere else, meaning the project IS the mount root.
#
# It is passed as `-r <root>` rather than glued onto every config path. Both forms are equivalent
# to the compiler, but `-r` is REQUIRED once `-b` points inside build/: without it the compiler
# resolves script.main against the wrong root and fails with "Could not find main SQRL script".
P="${SQRL_PACKAGE_PREFIX:-}"
if [ -n "$P" ]; then
  ROOT="${P%/}"                                   # the code agent told us where we are
elif ROOT="$(git rev-parse --show-prefix 2>/dev/null)"; then
  ROOT="${ROOT%/}"; ROOT="${ROOT:-.}"             # a repo checkout: our path within it
else
  ROOT="."                                        # not in a repo: this project is the root
fi

# The DataSQRL CLI version the code agent container ships; CI and local runs default to the same
# one so snapshots match. Override with SQRL_VERSION.
SQRL_VERSION="${SQRL_VERSION:-0.11.2}"
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
  # Worth a warning, not a failure: snapshots were generated with the pinned version, so a
  # different CLI can legitimately produce different output and fail tests that are fine.
  printf 'warning: datasqrl/cmd:%s is not available; falling back to %s\n' \
    "$SQRL_VERSION" "$IMAGE" >&2
}

# ── EDIT FOR YOUR PROJECT ────────────────────────────────────────────────────
# The environments this project's configs cover, and the sub-projects it ships. Both are
# declared rather than discovered, so that asking for something this project does not have
# fails loudly instead of matching nothing, running zero suites and still exiting 0.
ENVS="test prod"
SUBPROJECTS="creditcard_views"
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

# Each suite writes its own build folder, build/<sub-project> (the -b flag in the driver loop
# below), so one suite's build artifacts never overwrite a sibling's.

sqrl() {
  local verb="$1"; shift
  # Every named config must exist. A missing one means the suite line and this environment
  # disagree, and compiling a partial argument list would quietly review the wrong thing.
  local a missing=0
  for a in "$@"; do
    case "$a" in
      *.json) [ -f "$a" ] || { echo "missing config: $a" >&2; missing=1; } ;;
    esac
  done
  [ "$missing" = 1 ] && return 1
  # List mode: report what would run and return. Bash has already expanded the environment and
  # the path prefix, so the caller reads the real argument list without parsing this file. The
  # sub-project is named first so each line stands on its own.
  if [ -n "$LIST" ]; then
    printf 'SQRL_INVOCATION %s %s -r %s %s\n' "$SUITE" "$verb" "$ROOT" "$*"
    return 0
  fi

  if [ -x /opt/agent/cmd.sh ]; then
    /opt/agent/cmd.sh "$verb" -r "$ROOT" "$@"     # inside the code agent container
    return
  fi
  # CI / local developer machine: run the DataSQRL CLI image. Mount the REPOSITORY root at
  # /workspace (not just this project) so a sibling shared module this project consumes exists
  # inside the container too; `-r <project>` then points the compiler at this project.
  local root
  root="$(git rev-parse --show-toplevel 2>/dev/null)" || root="$PWD"
  # The image bakes TZ=America/Los_Angeles and every template's snapshots were generated under
  # it, so the container's default is left alone; TZ passes through only when set explicitly.
  resolve_image
  docker run --rm ${TZ:+-e TZ="$TZ"} -v "$root":/workspace \
    "$IMAGE" "$verb" -r "$ROOT" "$@"
}

# ── EDIT FOR YOUR PROJECT (optional): setup ──────────────────────────────────
# Anything the suites need first — generating or downloading test data too large for git,
# starting a fixture. Guard it with $LIST so listing stays instant and side-effect free.
# [ -n "$LIST" ] || ./scripts/generate-testdata.sh || exit 1
# ─────────────────────────────────────────────────────────────────────────────

# ── EDIT FOR YOUR PROJECT: the suite table ───────────────────────────────────
# One line per (sub-project, environment), naming that combination's configs in merge order —
# base first, environment config last, since a later file overrides an earlier one. Write the
# filenames out literally; any names work. Cover every pair of SUBPROJECTS x ENVS that this
# project actually has, and leave out the ones it does not: asking for a pair that is missing
# reports an error rather than compiling something half-declared.
#
#   <sub-project>/<env>) echo "<base config> <env config>" ;;
#
suite() {
  case "$1/$2" in
    creditcard_views/test) echo "creditcard_views-shared-package.json creditcard_views-test-package.json" ;;
    creditcard_views/prod) echo "creditcard_views-shared-package.json creditcard_views-prod-package.json" ;;
    *) return 1 ;;
  esac
}

# ─────────────────────────────────────────────────────────────────────────────
# Every selected sub-project runs even after one fails, so a single run reports every failure.
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
  # shellcheck disable=SC2086  # the declaration is a space-separated argument list, on purpose
  sqrl "$VERB" $args -b "build/$sub" || fail=1
done

# ── EDIT FOR YOUR PROJECT (optional): teardown ───────────────────────────────
# [ -n "$LIST" ] || ./scripts/teardown.sh
# ─────────────────────────────────────────────────────────────────────────────

exit $fail
