## What does this PR do?

<!-- A short description of the change and why it was made. -->

## Type of change

- [ ] Bug fix
- [ ] New feature / value
- [ ] Breaking change (bumps major version)
- [ ] Documentation / typo fix
- [ ] Dependency bump

## Checklist

- [ ] `helm lint . --strict` passes locally
- [ ] `helm template clair . --values ci/default-values.yaml` renders without error
- [ ] `helm template clair . --values ci/operator-values.yaml` renders without error
- [ ] `values.schema.json` updated for any new or changed values
- [ ] `README.md` updated if user-facing behaviour changed
- [ ] `CHANGELOG.md` entry added under `[Unreleased]`
- [ ] No plaintext secrets or credentials in any template output
