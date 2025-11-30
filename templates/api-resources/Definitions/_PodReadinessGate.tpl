{{- /*
  数据格式：
  - www.example.com/feature-1
  - www.example.com/feature-2
*/ -}}
{{- define "definitions.PodReadinessGate" -}}
  {{- /* conditionType string */ -}}
  {{- include "base.field" (list "conditionType" .) }}
{{- end }}
