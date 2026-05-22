# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.0] - 2026-05-22

### Changed
- Replaced `mode: operator` with `mode: distributed` — separate Deployments for indexer, matcher, and notifier matching Clair's upstream architecture
- Renamed `mode: deployment` to `mode: combo`, aligning with Clair's own mode naming
- Moved mode-specific settings under `combo.*` and `distributed.*` namespaces for clarity
- Moved notifier config from `notifier.*` to `combo.notifier.*` (combo mode) and `distributed.notifier.*` (distributed mode)
- Replaced top-level `ingress`, `service`, `autoscaling`, `pdb` keys with `combo.ingress`, `combo.service`, etc.

### Added
- Distributed mode: separate `indexer`, `matcher`, and `notifier` Deployments with ClusterIP Services
- Distributed mode: path-based Ingress routing (`/indexer`, `/matcher`, `/notifier`) for L7 load balancers
- Distributed mode: per-component HPA support
- Distributed mode: init containers for startup dependency ordering (matcher waits for indexer)
- `config.notifier` section in shared config values

### Removed
- Operator mode (`mode: operator`) — the upstream Clair operator is not production-ready
- `ClairInstance` CRD and all associated RBAC resources

## [0.1.0] - 2026-05-22

### Added
- Initial release of the Clair Helm chart
- Normal deployment mode (`mode: deployment`) with Clair running in `combo`, `indexer`, or `matcher` mode
- Bundled PostgreSQL 15 deployment with PVC and health probes
- Dedicated notifier deployment (`notifier.enabled`) running Clair in `notifier` mode
- Operator mode (`mode: operator`) with `ClairInstance` CRD, operator Deployment, and full RBAC
- Database password auto-generation with Secret lookup to persist across upgrades
- Config stored in Kubernetes Secrets (never ConfigMaps) to protect credentials
- Pod restart on config change via checksum annotation
- HPA, PDB, and Ingress support for the main Clair deployment
- Init containers for dependency ordering (PostgreSQL readiness, Clair readiness for notifier)
- `values.schema.json` for Helm-level input validation
- GitHub Actions workflows for lint/test and chart release via GitHub Pages
- ArtifactHub annotations for chart discoverability

[Unreleased]: https://github.com/hackertwinten/clair-helm/compare/clair-0.2.0...HEAD
[0.2.0]: https://github.com/hackertwinten/clair-helm/compare/clair-0.1.0...clair-0.2.0
[0.1.0]: https://github.com/hackertwinten/clair-helm/releases/tag/clair-0.1.0
