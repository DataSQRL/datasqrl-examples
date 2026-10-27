# AGENTS.md

## Dependabot

Every version this repository depends on is one Dependabot can bump, configured in `.github/dependabot.yml`
(daily, all ecosystems). Green Dependabot PRs are approved and squash-merged by
`.github/workflows/auto-merge-dependabot.yml`; GitHub Actions bumps are approved and left for a human.

| What | Where it lives |
|---|---|
| SQRL CLI (`datasqrl/cmd`) | `sqrl.Dockerfile`, read by `build.yml` and every `run-tests.sh` |
| Maven dependencies and plugins | `<artifactId>.version` properties in each standalone `pom.xml` |
| Maven/JDK image for CI | `.github/maven/Dockerfile` |
| Python tooling | `requirements.txt`, checked against `.github/python/Dockerfile` |
| GraphQL schema linter | `.github/graphql-lint/package.json` + lockfile, run on `.github/graphql-lint/Dockerfile` |
| GitHub Actions | `uses:` lines in `.github/workflows` |

A hand-written version must stay where Dependabot can see it: a property in a pom, a literal `FROM image:tag@sha256:<index digest>`
line, or a manifest listed above. Never inline a version in a workflow env var, a `docker run` image, or a `curl`'d download.
A new pom, Dockerfile or manifest directory needs a matching entry in `dependabot.yml` and a CI job that builds it.
