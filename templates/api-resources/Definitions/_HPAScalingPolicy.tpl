{{- define "definitions.HPAScalingPolicy" -}}
  {{- /* periodSeconds int */ -}}
  {{- $periodSeconds := include "base.getValue" (list . "periodSeconds") }}
  {{- if $periodSeconds }}
    {{- include "base.field" (list "periodSeconds" (list (int $periodSeconds) 1 1800) "base.int.range") }}
  {{- end }}

  {{- /* type string */ -}}
  {{- $type := include "base.getValue" (list . "type") }}
  {{- if $type }}
    {{- include "base.field" (list "type" $type) }}
  {{- end }}

  {{- /* value int */ -}}
  {{- $value := include "base.getValue" (list . "value") }}
  {{- if $value }}
    {{- include "base.field" (list "value" $value "base.int") }}
  {{- end }}
{{- end }}
