{{- /*
  数据格式：
  - www.example.com/feature-1
  - www.example.com/feature-2
*/ -}}
{{- define "definitions.PodReadinessGate" -}}
  {{- /* conditionType string */ -}}
  {{- $conditionType := include "base.getValue" (list . "conditionType") }}
  {{- if $conditionType }}
    {{- include "base.field" (list "conditionType" $conditionType) }}
  {{- end }}
{{- end }}
