# clair-helm

[![Lint and Test](https://github.com/hackertwinten/clair-helm/actions/workflows/lint-test.yml/badge.svg)](https://github.com/hackertwinten/clair-helm/actions/workflows/lint-test.yml)
[![Release](https://github.com/hackertwinten/clair-helm/actions/workflows/release.yml/badge.svg)](https://github.com/hackertwinten/clair-helm/actions/workflows/release.yml)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/clair-helm)](https://artifacthub.io/packages/helm/clair-helm/clair)

Helm chart for deploying [Clair](https://github.com/quay/clair) — the open-source container vulnerability static analysis tool by Red Hat/Quay.

Supports two deployment modes:

- **`deployment`** (default) — deploys Clair directly as Kubernetes resources (Deployment, Service, Secret, etc.)
- **`operator`** — installs a CRD (`ClairInstance`) and an operator controller that reconciles it

## Contents

- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Deployment modes](#deployment-modes)
- [Configuration](#configuration)
- [Components](#components)
- [Upgrading](#upgrading)
- [Uninstalling](#uninstalling)

---

## Prerequisites

- Kubernetes 1.24+
- Helm 3.10+
- `kubectl` configured against your cluster

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

Port-forward to access the API locally:

```bash
kubectl port-forward -n clair svc/clair 6060:6060
curl http://localhost:6060/api/v1/index_report
```

---

## Deployment modes

### Normal deployment (default)

Deploys all Clair components as standard Kubernetes resources. Best for most use cases.

```bash
helm install clair ./clair-helm -n clair --create-namespace
```

Resources created:

| Resource | Description |
|---|---|
| `Deployment/clair` | Clair main process (`combo` mode by default) |
| `Deployment/clair-notifier` | Dedicated notifier process (`notifier` mode) |
| `Deployment/clair-postgresql` | Bundled PostgreSQL 15 |
| `Service/clair` | ClusterIP on port 6060 (HTTP) and 8089 (introspection) |
| `Service/clair-notifier` | ClusterIP for the notifier |
| `Service/clair-postgresql` | ClusterIP for Postgres |
| `Secret/clair-db` | Database password (auto-generated) |
| `Secret/clair-config` | Full Clair config YAML (contains credentials) |
| `Secret/clair-notifier-config` | Notifier-mode config YAML |
| `PersistentVolumeClaim/clair-postgresql` | 10Gi data volume |

### Operator mode

Installs the `ClairInstance` CRD, the operator controller, and (optionally) a `ClairInstance` CR. The operator reconciles the CR into the actual Clair resources.

```bash
helm install clair ./clair-helm -n clair --create-namespace \
  --set mode=operator
```

Resources created:

| Resource | Description |
|---|---|
| `CustomResourceDefinition/clairinstances.clair.quay.io` | ClairInstance CRD |
| `Deployment/clair-operator` | Operator controller |
| `ClusterRole/clair-operator` | RBAC for the operator |
| `ClusterRoleBinding/clair-operator` | Binds the role to the operator SA |
| `ServiceAccount/clair-operator` | Operator service account |
| `ClairInstance/clair` | Instance CR (if `operator.instance.create=true`) |

> **Note:** The operator image (`operator.image.repository`) must be a controller that understands the `ClairInstance` CRD defined in this chart. The default `quay.io/projectquay/clair-operator` is a placeholder — replace it with your actual operator image.

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
helm install clair ./clair-helm -n clair --create-namespace \
  --set notifier.enabled=false
```

When `notifier.enabled=false` and `config.mode=combo`, the main Clair process handles notifications internally.

### Enable ingress

```bash
helm install clair ./clair-helm -n clair --create-namespace \
  --set ingress.enabled=true \
  --set ingress.className=nginx \
  --set "ingress.hosts[0].host=clair.example.com" \
  --set "ingress.hosts[0].paths[0].path=/" \
  --set "ingress.hosts[0].paths[0].pathType=Prefix"
```

### Enable HPA

```bash
helm install clair ./clair-helm -n clair --create-namespace \
  --set autoscaling.enabled=true \
  --set autoscaling.minReplicas=2 \
  --set autoscaling.maxReplicas=5
```

### Set resource limits

```yaml
# custom-values.yaml
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

```bash
helm install clair ./clair-helm -n clair --create-namespace -f custom-values.yaml
```

### Configure webhook notifications

```yaml
# custom-values.yaml
notifier:
  config:
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
| `mode` | `deployment` | Deployment mode: `deployment` or `operator` |
| `nameOverride` | `""` | Override the chart name |
| `fullnameOverride` | `""` | Override the full release name |

### Clair

| Key | Default | Description |
|---|---|---|
| `image.repository` | `quay.io/projectquay/clair` | Clair image |
| `image.tag` | `4.7.4` | Image tag (defaults to `appVersion`) |
| `replicaCount` | `1` | Number of Clair replicas |
| `config.mode` | `combo` | Clair process mode: `combo`, `indexer`, `matcher` |
| `config.logLevel` | `info` | Log level: `debug`, `info`, `warn`, `error` |
| `config.indexer.migrations` | `true` | Run DB migrations on startup |
| `config.matcher.period` | `6h` | How often to sync vulnerability data |
| `config.matcher.disableUpdaters` | `false` | Disable vulnerability feed updates |
| `service.type` | `ClusterIP` | Service type |
| `service.port` | `6060` | HTTP API port |
| `service.introspectionPort` | `8089` | Metrics/health port |
| `ingress.enabled` | `false` | Enable Ingress |
| `autoscaling.enabled` | `false` | Enable HPA |
| `pdb.enabled` | `false` | Enable PodDisruptionBudget |

### Database

| Key | Default | Description |
|---|---|---|
| `database.externalConnString` | `""` | Full PostgreSQL connection string (disables bundled Postgres) |
| `database.name` | `clair` | Database name |
| `database.user` | `clair` | Database user |
| `database.password` | `""` | Password (auto-generated if empty) |

### PostgreSQL (bundled)

| Key | Default | Description |
|---|---|---|
| `postgresql.enabled` | `true` | Deploy bundled PostgreSQL |
| `postgresql.image.tag` | `15-alpine` | PostgreSQL image tag |
| `postgresql.persistence.enabled` | `true` | Enable PVC |
| `postgresql.persistence.size` | `10Gi` | PVC size |
| `postgresql.persistence.storageClass` | `""` | Storage class (cluster default if empty) |

### Notifier

| Key | Default | Description |
|---|---|---|
| `notifier.enabled` | `true` | Deploy a dedicated notifier pod |
| `notifier.replicaCount` | `1` | Number of notifier replicas |
| `notifier.config.pollInterval` | `5m` | How often to poll for new notifications |
| `notifier.config.deliveryInterval` | `1m` | How often to attempt delivery |
| `notifier.config.indexerAddr` | `""` | Indexer address (defaults to main Clair service) |
| `notifier.config.matcherAddr` | `""` | Matcher address (defaults to main Clair service) |
| `notifier.config.webhook.target` | `""` | Webhook delivery URL |
| `notifier.config.webhook.callback` | `""` | Callback URL for the notifier |

### Operator mode

| Key | Default | Description |
|---|---|---|
| `operator.image.repository` | `quay.io/projectquay/clair-operator` | Operator image |
| `operator.image.tag` | `latest` | Operator image tag |
| `operator.replicaCount` | `1` | Operator replicas (leader election handles >1) |
| `operator.instance.create` | `true` | Create a `ClairInstance` CR on install |
| `operator.instance.name` | `clair` | Name of the `ClairInstance` CR |
| `operator.instance.replicas` | `1` | Desired Clair replicas in the CR spec |
| `operator.instance.database.secretRef` | `""` | Pre-existing Secret with `connstring` key |

---

## Components

### Clair modes

Clair v4 supports four operating modes set via `CLAIR_MODE` (or `config.mode`):

| Mode | Description |
|---|---|
| `combo` | Runs indexer + matcher + notifier in one process. Best for small/medium deployments. |
| `indexer` | Fetches and indexes container layer data. |
| `matcher` | Matches indexed packages against vulnerability feeds. |
| `notifier` | Watches for new vulnerabilities and delivers notifications. |

This chart runs the main pod in `combo` mode by default. When `notifier.enabled=true`, a separate pod is deployed in `notifier` mode for independent scaling, while the main pod continues in `combo` mode.

### Security

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

> **Note:** The `ClairInstance` CRD (operator mode) has `helm.sh/resource-policy: keep` and will **not** be deleted automatically. Remove it manually if no longer needed:
>
> ```bash
> kubectl delete crd clairinstances.clair.quay.io
> ```

The PostgreSQL PVC is also retained by default Kubernetes behavior. Delete it manually to free storage:

```bash
kubectl delete pvc clair-postgresql -n clair
```
