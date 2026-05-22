# Contributing

Thank you for your interest in contributing to clair-helm.

## Ways to contribute

- Report bugs via [GitHub Issues](../../issues/new?template=bug_report.yaml)
- Suggest features via [GitHub Issues](../../issues/new?template=feature_request.yaml)
- Submit pull requests for fixes and improvements

## Development setup

### Prerequisites

- [Helm](https://helm.sh/docs/intro/install/) v3.10+
- [kubectl](https://kubernetes.io/docs/tasks/tools/) configured against a cluster, or a local cluster via [kind](https://kind.sigs.k8s.io/) / [minikube](https://minikube.sigs.k8s.io/)
- [chart-testing (ct)](https://github.com/helm/chart-testing) for full lint runs (optional)

### Local cluster with kind

```bash
kind create cluster --name clair-dev
```

### Lint and render locally

```bash
# Lint with default values
helm lint .

# Lint with strict schema validation
helm lint . --strict

# Render templates without installing
helm template clair . --values ci/default-values.yaml
helm template clair . --values ci/operator-values.yaml
```

### Install locally for manual testing

```bash
# Create namespace
kubectl create namespace clair

# Install with default values (deployment mode)
helm install clair . -n clair --values ci/default-values.yaml

# Watch pods come up
kubectl get pods -n clair -w

# Uninstall
helm uninstall clair -n clair
```

## Making changes

1. Fork the repository and create a branch from `main`:
   ```bash
   git checkout -b fix/my-fix
   ```

2. Make your changes. Keep the following in mind:
   - Update `values.yaml` defaults for any new configuration you add
   - Update `values.schema.json` to validate new values
   - Update `README.md` if you add or change user-facing options
   - Add an entry to `CHANGELOG.md` under `[Unreleased]`
   - Run `helm lint . --strict` before pushing

3. Open a pull request against `main`. The PR template will guide you through the checklist.

## Versioning

This project follows [Semantic Versioning](https://semver.org/):

- `patch` (0.1.**x**) — bug fixes, dependency bumps, no API changes
- `minor` (0.**x**.0) — new backwards-compatible features or values
- `major` (**x**.0.0) — breaking changes to the chart API or default behavior

The chart version in `Chart.yaml` and `appVersion` (the default Clair image tag) are bumped separately.

## Code style

- Helm templates: 2-space indentation, `nindent` for multi-line blocks
- Template helpers go in `templates/_helpers.tpl`
- Guard every resource with a `{{- if ... }}` so unused components produce no output
- No plaintext secrets in `ConfigMap` — credentials always go in `Secret`

## Reporting security issues

See [SECURITY.md](SECURITY.md). Do not open public issues for vulnerabilities.
