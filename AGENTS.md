# AGENTS.md

`README.md` is its public page (GitHub, Marketplace): only user-facing content goes there, internals are here

## Tech summary

- Language: YAML composite action, multi-line steps are Bash scripts in `scripts/`.
  Combines `actions/setup-java` and `aws-actions/configure-aws-credentials`
- Runtime: GitHub Actions runner
- Artifact: git tag `v{version}` and floating tags `v{major}`, `v{major}.{minor}`,
  released by `release.yml` with *release* on push to `main`

## Context

Used by *gha-setup-java* (private wrapper with AgileCustoms defaults) and by *release* for Maven artifacts

## How it works

| Path                 | What                                                                          |
|----------------------|-------------------------------------------------------------------------------|
| `action.yml`         | the action: inputs and steps                                                  |
| `scripts/*.sh`       | multi-line steps (validate, CodeArtifact token, settings.xml), header: inputs |
| `ci.settings.xml`    | settings.xml the action generates, shown to users in README                   |
| `local.settings.xml` | settings.xml for developer machines, shown to users in README                 |
| `test/`              | fake `aws` CLI and expected settings.xml for tests in CI                      |

## Change together

- README inputs table must match `action.yml` inputs (names, required, defaults)

## Development

`make lint` (actionlint, shellcheck), all targets are in [Makefile](Makefile).
Tests run only in CI (`build.yml`: `Input-Validation`, `Test`): the action runs end to end with a fake `aws` CLI

## Release procedure

The action is public, others depend on it. There is no prerelease channel: `Input-Validation` and `Test`
run the action end to end before `Release`, then every push to `main` is released.
Users on floating tag `v{major}` get every minor and patch release at once
