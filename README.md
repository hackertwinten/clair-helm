# clair-helm

[![Lint and Test](https://github.com/hackertwinten/clair-helm/actions/workflows/lint-test.yml/badge.svg)](https://github.com/hackertwinten/clair-helm/actions/workflows/lint-test.yml)
[![Release](https://github.com/hackertwinten/clair-helm/actions/workflows/release.yml/badge.svg)](https://github.com/hackertwinten/clair-helm/actions/workflows/release.yml)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/clair-helm)](https://artifacthub.io/packages/helm/clair-helm/clair)

Helm chart for deploying [Clair](https://github.com/quay/clair) — the open-source container vulnerability static analysis tool by Red Hat/Quay.

Supports two deployment modes:

- **`combo`** (default) — single all-in-one Clair process running indexer + matcher, with an optional separate notifier pod
- **`distributed`** — separate Deployment per component (indexer, matcher, notifier) with path-based Ingress routing

## Contents

- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Deployment modes](#deployment-modes)
- [Configuration](#configuration)
- [Values reference](#values-reference)
- [Upgrading](#upgrading)
- [Uninstalling](#uninstalling)

---

## Prerequisites

- Kubernetes 1.24+
- Helm 3.10+
- `kubectl` configured against your cluster
- For distributed mode: a Layer 7 Ingress controller (nginx, traefik, etc.)

---

## Installation

### From the Helm repository (recommended)

```bash
helm repo add clair-helm https://hackertwinten.github.io/clair-helm
helm repo update
helm install clair clair-helm/clair -n clair --create-namespace
```

### From source

```bash
git clone https://github.com/hackertwinten/clair-helm.git
cd clair-helm
helm install clair . -n clair --create-namespace
```

Verify the release:

```bash
helm status clair -n clair
kubectl get pods -n clair
```

Run the health check tests:

```bash
helm test clair -n clair
```

Port-forward to access the API locally (combo mode):

```bash
kubectl port-forward -n clair svc/clair 6060:6060
curl http://localhost:6060/api/v1/index_report
```

---

## Deployment modes

### Combo mode (default)

Runs all Clair components in a single process (`CLAIR_MODE=combo`). An optional second pod can handle notifications independently.

```bash
helm install clair ./clair-helm -n clair --create-namespace
```

Resources created:

| Resource | Description |
|---|---|
| `Deployment/clair` | Clair main process in `combo` mode |
| `Deployment/clair-notifier` | Dedicated notifier pod (`combo.notifier.enabled=true`) |
| `Deployment/clair-postgresql` | Bundled PostgreSQL 15 |
| `Service/clair` | ClusterIP on port 6060 and 8089 |
| `Service/clair-notifier` | ClusterIP for the notifier |
| `Service/clair-postgresql` | ClusterIP for Postgres |
| `Secret/clair-db` | Database password (auto-generated) |
| `Secret/clair-config` | Clair config YAML |
| `PersistentVolumeClaim/clair-postgresql` | 10Gi data volume |

### Distributed mode

Runs each Clair component as its own Deployment. Requires a Layer 7 Ingress controller to route requests by path.

```bash
helm install clair ./clair-helm -n clair --create-namespace \
  --set mode=distributed \
  --set distributed.ingress.enabled=true \
  --set distributed.ingress.className=nginx \
  --set distributed.ingress.host=clair.example.com
```

Resources created:

| Resource | Description |
|---|---|
| `Deployment/clair-indexer` | Indexer component |
| `Deployment/clair-matcher` | Matcher component |
| `Deployment/clair-notifier` | Notifier component (if enabled) |
| `Service/clair-indexer` | ClusterIP for indexer |
| `Service/clair-matcher` | ClusterIP for matcher |
| `Service/clair-notifier` | ClusterIP for notifier |
| `Ingress/clair` | Routes `/indexer`, `/matcher`, `/notifier` to each service |
| `Deployment/clair-postgresql` | Bundled PostgreSQL 15 |
| `Secret/clair-config` | Shared Clair config YAML |

The Ingress routes traffic by path prefix:
- `clair.example.com/indexer/*` → indexer
- `clair.example.com/matcher/*` → matcher
- `clair.example.com/notifier/*` → notifier

---

## Configuration

All options are in [`values.yaml`](values.yaml). Common overrides:

### Use an external PostgreSQL database

```bash
helm install clair ./clair-helm -n clair --create-namespace \
  --set postgresql.enabled=false \
  --set database.externalConnString="host=mydb.example.com port=5432 dbname=clair user=clair password=s3cr3t sslmode=require"
```

### Set a specific database password

By default the chart generates a random 32-character password on first install and reuses it on upgrades. To set your own:

```bash
helm install clair ./clair-helm -n clair --create-namespace \
  --set database.password=mysecretpassword
```

### Disable the notifier

```bash
# Combo mode
helm install clair ./clair-helm -n clair --create-namespace \
  --set combo.notifier.enabled=false

# Distributed mode
helm install clair ./clair-helm -n clair --create-namespace \
  --set mode=distributed \
  --set distributed.notifier.enabled=false
```

### Enable Ingress (combo mode)

```bash
helm install clair ./clair-helm -n clair --create-namespace \
  --set combo.ingress.enabled=true \
  --set combo.ingress.className=nginx \
  --set "combo.ingress.hosts[0].host=clair.example.com" \
  --set "combo.ingress.hosts[0].paths[0].path=/" \
  --set "combo.ingress.hosts[0].paths[0].pathType=Prefix"
```

### Enable HPA (combo mode)

```bash
helm install clair ./clair-helm -n clair --create-namespace \
  --set combo.autoscaling.enabled=true \
  --set combo.autoscaling.minReplicas=2 \
  --set combo.autoscaling.maxReplicas=5
```

### Enable per-component HPA (distributed mode)

```bash
helm install clair ./clair-helm -n clair --create-namespace \
  --set mode=distributed \
  --set distributed.indexer.autoscaling.enabled=true \
  --set distributed.indexer.autoscaling.maxReplicas=10 \
  --set distributed.matcher.autoscaling.enabled=true \
  --set distributed.matcher.autoscaling.maxReplicas=10
```

### Set resource limits

```yaml
# custom-values.yaml
combo:
  resources:
    requests:
      cpu: 200m
      memory: 512Mi
    limits:
      cpu: 1000m
      memory: 1Gi

postgresql:
  resources:
    requests:
      cpu: 100m
      memory: 256Mi
    limits:
      cpu: 500m
      memory: 512Mi
```

### Configure webhook notifications

```yaml
# custom-values.yaml
config:
  notifier:
    webhook:
      target: "https://my-webhook.example.com/clair"
      callback: "http://clair:6060/notifier/api/v1/notifications"
      signed: false
```

---

## Values reference

### Global

| Key | Default | Description |
|---|---|---|
| `mode` | `combo` | Deployment mode: `combo` or `distributed` |
| `nameOverride` | `""` | Override the chart name |
| `fullnameOverride` | `""` | Override the full release name |
| `image.repository` | `quay.io/projectquay/clair` | Clair image |
| `image.tag` | `4.9.0` | Image tag (defaults to `appVersion`) |
| `config.logLevel` | `info` | Log level: `debug`, `info`, `warn`, `error` |
| `config.indexer.migrations` | `true` | Run DB migrations on startup |
| `config.matcher.period` | `6h` | How often to sync vulnerability data |
| `config.matcher.disableUpdaters` | `false` | Disable vulnerability feed updates |

### Database

| Key | Default | Description |
|---|---|---|
| `database.externalConnString` | `""` | Full PostgreSQL DSN (disables bundled Postgres) |
| `database.name` | `clair` | Database name |
| `database.user` | `clair` | Database user |
| `database.password` | `""` | Password (auto-generated if empty) |

### PostgreSQL (bundled)

| Key | Default | Description |
|---|---|---|
| `postgresql.enabled` | `true` | Deploy bundled PostgreSQL |
| `postgresql.image.tag` | `17-alpine` | PostgreSQL image tag |
| `postgresql.persistence.enabled` | `true` | Enable PVC |
| `postgresql.persistence.existingClaim` | `""` | Use a pre-existing PVC instead of creating one |
| `postgresql.persistence.size` | `10Gi` | PVC size (ignored when `existingClaim` is set) |
| `postgresql.persistence.storageClass` | `""` | Storage class (cluster default if empty) |

### Combo mode

| Key | Default | Description |
|---|---|---|
| `combo.replicaCount` | `1` | Number of Clair replicas |
| `combo.service.type` | `ClusterIP` | Service type |
| `combo.service.port` | `6060` | HTTP API port |
| `combo.ingress.enabled` | `false` | Enable Ingress |
| `combo.autoscaling.enabled` | `false` | Enable HPA |
| `combo.pdb.enabled` | `false` | Enable PodDisruptionBudget |
| `combo.notifier.enabled` | `true` | Deploy a dedicated notifier pod |
| `combo.notifier.replicaCount` | `1` | Notifier replicas |

### Distributed mode

| Key | Default | Description |
|---|---|---|
| `distributed.ingress.enabled` | `true` | Enable path-based Ingress (required for external access) |
| `distributed.ingress.host` | `clair.example.com` | Ingress hostname |
| `distributed.ingress.className` | `""` | Ingress class name |
| `distributed.indexer.replicaCount` | `2` | Indexer replicas |
| `distributed.indexer.autoscaling.enabled` | `false` | Enable HPA for indexer |
| `distributed.matcher.replicaCount` | `2` | Matcher replicas |
| `distributed.matcher.autoscaling.enabled` | `false` | Enable HPA for matcher |
| `distributed.notifier.enabled` | `true` | Deploy notifier |
| `distributed.notifier.replicaCount` | `1` | Notifier replicas |

---

## Security

All pods run with:
- `runAsNonRoot: true`
- `allowPrivilegeEscalation: false`
- `readOnlyRootFilesystem: true`
- All Linux capabilities dropped

The Clair config (which contains the database password) is stored in a Kubernetes `Secret`, not a `ConfigMap`. Pods automatically restart when the config secret changes via a checksum annotation.

---

## Upgrading

```bash
helm upgrade clair ./clair-helm -n clair
```

The database password is preserved across upgrades — the chart uses `lookup` to read the existing Secret and reuses the same password rather than generating a new one.

---

## Uninstalling

```bash
helm uninstall clair -n clair
```

The PostgreSQL PVC is retained by default Kubernetes behavior. Delete it manually to free storage:

```bash
kubectl delete pvc clair-postgresql -n clair
```
