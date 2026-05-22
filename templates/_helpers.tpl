{{/*
Expand the name of the chart.
*/}}
{{- define "clair.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "clair.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Chart label.
*/}}
{{- define "clair.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels.
*/}}
{{- define "clair.labels" -}}
helm.sh/chart: {{ include "clair.chart" . }}
{{ include "clair.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels.
*/}}
{{- define "clair.selectorLabels" -}}
app.kubernetes.io/name: {{ include "clair.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Notifier selector labels.
*/}}
{{- define "clair.notifier.selectorLabels" -}}
app.kubernetes.io/name: {{ printf "%s-notifier" (include "clair.name" .) }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
ServiceAccount name for the main deployment.
*/}}
{{- define "clair.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "clair.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
ServiceAccount name for the operator.
*/}}
{{- define "clair.operator.serviceAccountName" -}}
{{- if .Values.operator.serviceAccount.create }}
{{- default (printf "%s-operator" (include "clair.fullname" .)) .Values.operator.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.operator.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
PostgreSQL service hostname.
*/}}
{{- define "clair.postgresHost" -}}
{{- if .Values.postgresql.enabled }}
{{- printf "%s-postgresql" (include "clair.fullname" .) }}
{{- else }}
{{- required "database.host is required when postgresql.enabled=false and database.externalConnString is empty" .Values.database.host }}
{{- end }}
{{- end }}

{{/*
Resolve the DB password: prefer existing Secret > values > auto-generate.
Call this inside a template that already has the $secretObj available, or use
the clair.dbPassword helper which does the lookup itself.
*/}}
{{- define "clair.dbPassword" -}}
{{- $secretName := printf "%s-db" (include "clair.fullname" .) -}}
{{- $secretObj := lookup "v1" "Secret" .Release.Namespace $secretName -}}
{{- if and $secretObj $secretObj.data (index $secretObj.data "password") -}}
{{- index $secretObj.data "password" | b64dec -}}
{{- else if .Values.database.password -}}
{{- .Values.database.password -}}
{{- else -}}
{{- randAlphaNum 32 -}}
{{- end -}}
{{- end }}

{{/*
Build a PostgreSQL connection string from components.
Usage: pass a dict with keys: host, port, dbname, user, password
*/}}
{{- define "clair.connString" -}}
{{- if .Values.database.externalConnString -}}
{{- .Values.database.externalConnString -}}
{{- else -}}
{{- printf "host=%s port=%d dbname=%s user=%s password=%s sslmode=disable"
    (include "clair.postgresHost" .)
    (int .Values.postgresql.service.port)
    .Values.database.name
    .Values.database.user
    (include "clair.dbPassword" .) -}}
{{- end -}}
{{- end }}

{{/*
Resolved notifier indexer address (defaults to the main Clair service).
*/}}
{{- define "clair.notifier.indexerAddr" -}}
{{- if .Values.notifier.config.indexerAddr -}}
{{- .Values.notifier.config.indexerAddr -}}
{{- else -}}
{{- printf "http://%s:%d" (include "clair.fullname" .) (int .Values.service.port) -}}
{{- end -}}
{{- end }}

{{/*
Resolved notifier matcher address (defaults to the main Clair service).
*/}}
{{- define "clair.notifier.matcherAddr" -}}
{{- if .Values.notifier.config.matcherAddr -}}
{{- .Values.notifier.config.matcherAddr -}}
{{- else -}}
{{- printf "http://%s:%d" (include "clair.fullname" .) (int .Values.service.port) -}}
{{- end -}}
{{- end }}
