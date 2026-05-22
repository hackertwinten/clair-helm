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

{{- define "clair.selectorLabels" -}}
app.kubernetes.io/name: {{ include "clair.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Component selector labels.
*/}}
{{- define "clair.indexer.selectorLabels" -}}
app.kubernetes.io/name: {{ printf "%s-indexer" (include "clair.name" .) }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "clair.matcher.selectorLabels" -}}
app.kubernetes.io/name: {{ printf "%s-matcher" (include "clair.name" .) }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "clair.notifier.selectorLabels" -}}
app.kubernetes.io/name: {{ printf "%s-notifier" (include "clair.name" .) }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
ServiceAccount name.
*/}}
{{- define "clair.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "clair.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
PostgreSQL service hostname.
*/}}
{{- define "clair.postgresHost" -}}
{{- if .Values.postgresql.enabled }}
{{- printf "%s-postgresql" (include "clair.fullname" .) }}
{{- else }}
{{- required "database.externalConnString is required when postgresql.enabled=false" .Values.database.externalConnString }}
{{- end }}
{{- end }}

{{/*
Resolve the DB password: existing Secret > values override > auto-generate.
Stable across helm upgrades via Secret lookup.
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
PostgreSQL connection string.
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
Distributed mode: indexer service address.
*/}}
{{- define "clair.indexerAddr" -}}
{{- printf "http://%s-indexer:6060" (include "clair.fullname" .) -}}
{{- end }}

{{/*
Distributed mode: matcher service address.
*/}}
{{- define "clair.matcherAddr" -}}
{{- printf "http://%s-matcher:6060" (include "clair.fullname" .) -}}
{{- end }}

{{/*
Combo mode: notifier indexer address — points to main combo service by default.
*/}}
{{- define "clair.combo.notifier.indexerAddr" -}}
{{- printf "http://%s:6060" (include "clair.fullname" .) -}}
{{- end }}

{{/*
Combo mode: notifier matcher address — points to main combo service by default.
*/}}
{{- define "clair.combo.notifier.matcherAddr" -}}
{{- printf "http://%s:6060" (include "clair.fullname" .) -}}
{{- end }}
