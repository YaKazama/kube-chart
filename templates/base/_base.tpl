{{- define "base.chart" -}}
  {{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "base.helmLabels" -}}
  {{- nindent 0 "" -}}helm.sh/chart: {{ include "base.chart" . }}
  {{- nindent 0 "" -}}app.kubernetes.io/version: {{ .Chart.AppVersion }}
  {{- nindent 0 "" -}}app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "base.name" -}}
  {{- $__name := coalesce .Context.fullname .Context.name .Values.fullname .Values.name .Values.global.fullname .Values.global.name .Chart.Name }}

  {{- $__const := include "base.env" . | fromYaml }}
{{- end }}
