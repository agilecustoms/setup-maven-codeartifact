# AGENTS.md

Shared agilecustoms rules (git, code style) are in `../tools/agents/AGENTS.md`.
This file is `setup-maven-codeartifact` specific

`README.md` is its public page (GitHub, Marketplace): only user-facing content goes there, internals are here

## Tech summary

- Language: YAML composite action, multi-line steps are Bash scripts in `scripts/`.
  Combines `actions/setup-java` and `aws-actions/configure-aws-credentials`
- Runtime: GitHub Actions runner
- Artifact: git tag `v{version}` and floating tags `v{major}`, `v{major}.{minor}`,
  released by `release.yml` with *release* on push to `main`

## Context

Used by *gha-setup-java* (private wrapper with AgileCustoms defaults) and by *release* for Maven artifacts

## Layout

| Path                 | What                                                                          |
|----------------------|-------------------------------------------------------------------------------|
| `action.yml`         | the action: inputs and steps                                                  |
| `scripts/*.sh`       | multi-line steps (validate, CodeArtifact token, settings.xml), header: inputs |
| `ci.settings.xml`    | settings.xml the action generates, shown to users in README                   |
| `local.settings.xml` | settings.xml for developer machines, shown to users in README                 |
| `test/`              | fake `aws` CLI and expected settings.xml for tests in CI                      |

## Development

`make lint` (actionlint, shellcheck), all targets are in [Makefile](Makefile).
Tests run only in CI (`build.yml`: `Input-Validation`, `Test`): the action runs end to end with a fake `aws` CLI

## Documentation rules

- the repo is public: in docs and examples use placeholders (`mycompany`, `123456789012`), not real ids
- README inputs table must match `action.yml` inputs (names, required, defaults)
