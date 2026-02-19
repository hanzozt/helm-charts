{{/*
Expand the name of the chart.
*/}}

{{- define "zt-router.name" -}}
    {{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.  We truncate at 63 chars because some
Kubernetes name fields are limited to this (by the DNS naming spec).  If release
name contains chart name it will be used as a full name.
*/}}
{{- define "zt-router.fullname" -}}
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
{{- define "zt-router.chart" -}}
    {{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "zt-router.labels" -}}
helm.sh/chart: {{ include "zt-router.chart" . }}
{{ include "zt-router.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "zt-router.selectorLabels" -}}
app.kubernetes.io/name: {{ include "zt-router.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "zt-router.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "zt-router.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
help the alt-certificate template find its DNS SAN by looking up the advertised
host of an additional listener
*/}}
{{- define "zt-router.lookupAltServerCertHost" -}}
{{- $listenerName := .additionalListenerName -}}
{{- $additionalListeners:= .additionalListeners -}}
{{- $matchedListenerHost := "" -}}
{{- range $additionalListeners }}
  {{- if eq .name $listenerName }}
    {{- $matchedListenerHost = .advertisedHost }}
  {{- end }}
{{- end }}
{{- if $matchedListenerHost }}
  {{- $matchedListenerHost }}
{{- else }}
  {{- fail "No matched listener host found" }}
{{- end }}
{{- end }}

{{/*
help the alt-certificate template find the members of identity.altServerCerts
that are managed by cert-manager
*/}}
{{- define "zt-router.getCertManagerAltServerCerts" -}}
{{- $filteredCerts := list -}}
{{- range . -}}
  {{- if eq .mode "certManager" -}}
    {{- $filteredCerts = append $filteredCerts . -}}
  {{- end -}}
{{- end -}}
{{- dict "certManagerCerts" $filteredCerts | toJson -}}
{{- end -}}

{{/*
help the configmap template find the mount path of an alternative server
certificate by looking up the secret name in the list of additional volumes
*/}}
{{- define "zt-router.lookupVolumeMountPath" -}}
{{- $secretName := .secretName -}}
{{- $matchingVolumeMountPath := "" -}}
{{- range .additionalVolumes }}
  {{- if and (eq .volumeType "secret") (eq .secretName $secretName) }}
    {{- $matchingVolumeMountPath = .mountPath }}
  {{- end }}
{{- end }}
{{- if $matchingVolumeMountPath }}
  {{- $matchingVolumeMountPath }}
{{- else }}
  {{- fail (printf "No matching additionalVolume found for secretName: %s" $secretName) }}
{{- end }}
{{- end -}}

{{/*
render as an inline template if the value is a string containing a go template,
else return the literal value
*/}}
{{- define "zt-router.tplOrLiteral" -}}
{{- $value := .value -}}
{{- $context := .context -}}
{{- if typeIs "string" $value -}}
  {{- $trimmed := trim $value -}}
  {{- if and (hasPrefix "{{" $trimmed) (hasSuffix "}}" $trimmed) -}}
    {{- tpl $value $context -}}
  {{- else -}}
    {{- $value -}}
  {{- end -}}
{{- else -}}
  {{- $value -}}
{{- end -}}
{{- end -}}