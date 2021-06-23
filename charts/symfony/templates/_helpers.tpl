{{/*
Expand the name of the chart.
*/}}
{{- define "symfony.name" -}}
    {{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "symfony.fullname" -}}
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
Create chart name and version as used by the chart label.
*/}}
{{- define "symfony.chart" -}}
    {{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "symfony.labels" -}}
helm.sh/chart: {{ include "symfony.chart" . }}
{{ include "symfony.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "symfony.selectorLabels" -}}
app.kubernetes.io/name: {{ include "symfony.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "symfony.app-container" -}}
    {{- $dot := index . 0 -}}
    {{- $opts := index . 1 -}}

    {{- $image := print $dot.Values.image.repository ":" $dot.Values.image.tag -}}
    {{- $configMount := (dict "name" "config" "mountPath" "/var/www/html/.env.local" "subPath" ".env") -}}
    {{- $volumeMounts := concat (list $configMount) $dot.Values.extraAppVolumeMounts -}}

    {{- $defaults := dict "image" $image "volumeMounts" $volumeMounts -}}
    {{- merge (dict) $defaults $opts | list | toYaml -}}
{{- end -}}

{{- define "symfony.env" -}}
    {{- $cm := lookup "v1" "ConfigMap" .Release.Namespace (include "symfony.fullname" .) -}}
    {{- $cmData := or $cm.data (dict) -}}
    {{- $env := index $cmData ".env" -}}
    {{- if $env -}}
        {{- $env -}}
    {{- else -}}
        {{- tpl .Values.defaultConfig . -}}
    {{- end -}}
{{- end -}}
