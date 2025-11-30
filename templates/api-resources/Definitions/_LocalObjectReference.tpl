{{- /*
  数据格式：
    - secret-name
*/ -}}
{{- define "definitions.LocalObjectReference" -}}
  {{- /* name string */ -}}
  {{- include "base.field" (list "name" .) }}
{{- end }}
