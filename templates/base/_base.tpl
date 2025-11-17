{{- define "base.chart" -}}
  {{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "base.helmLabels" -}}
  {{- nindent 0 "" -}}helm.sh/chart: {{ include "base.chart" . }}
  {{- nindent 0 "" -}}app.kubernetes.io/version: {{ .Chart.AppVersion }}
  {{- nindent 0 "" -}}app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "base.name" -}}
  {{- $__name := "" }}

  {{- if kindIs "string" . }}
    {{- $__name = . }}
  {{- else if kindIs "map" . }}
    {{- if .Context }}
      {{- $__name = coalesce $__name .Context.fullname .Context.name }}
    {{- end }}
    {{- if .Values }}
      {{- $__name = coalesce $__name .Values.fullname .Values.name }}
      {{- if .Values.global }}
        {{- $__name = coalesce $__name .Values.global.fullname .Values.global.name }}
      {{- end }}
    {{- end }}
    {{- if .Chart }}
      {{- $__name = coalesce $__name .Chart.Name }}
    {{- end }}
    {{- if empty $__name }}
      {{- $__name = index (values . | sortAlpha) 0 }}
    {{- end }}
    {{- $__name = include "base.string" $__name | lower | nospace | trimSuffix "-" }}
  {{- else }}
    {{- include "base.faild" . }}
  {{- end }}

  {{- $__const := include "base.env" . | fromYaml }}

  {{- if regexMatch $__const.regexRFC1035 $__name }}
    {{- $__name }}
  {{- else }}
    {{- include "base.faild" . }}
  {{- end }}
{{- end }}
