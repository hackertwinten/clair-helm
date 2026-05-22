# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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

[Unreleased]: https://github.com/hackertwinten/clair-helm/compare/clair-0.1.0...HEAD
[0.1.0]: https://github.com/hackertwinten/clair-helm/releases/tag/clair-0.1.0
