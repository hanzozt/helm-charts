{{/*
Expand the name of the chart.
*/}}

{{- define "zt-browzer-bootstrapper.name" -}}
    {{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "zt-browzer-bootstrapper.fullname" -}}
    {{- if .Values.fullnameOverride }}
        {{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
    {{- else }}
        {{- $name := default ( trimPrefix "zt-" .Chart.Name ) .Values.nameOverride }}
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
{{- define "zt-browzer-bootstrapper.chart" -}}
    {{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "zt-browzer-bootstrapper.labels" -}}
helm.sh/chart: {{ include "zt-browzer-bootstrapper.chart" . }}
{{ include "zt-browzer-bootstrapper.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "zt-browzer-bootstrapper.selectorLabels" -}}
app.kubernetes.io/name: {{ include "zt-browzer-bootstrapper.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "zt-browzer-bootstrapper.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "zt-browzer-bootstrapper.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Default ingress http config
*/}}
{{- define "ingress-http-def" -}}
      http:
        paths:
          - path: /
            pathType: "Prefix"
            backend:
              service:
                name: {{ include "zt-browzer-bootstrapper.fullname" . }}
                port:
                  name: {{ .Values.service.portName }}
{{- end }}
