{{- define "definitions.MetricTarget" -}}
  {{- /* type string */ -}}
  {{- $type := include "base.getValue" (list . "type") }}
  {{- $typeAllows := list "Utilization" "Value" "AverageValue" }}
  {{- if $type }}
    {{- include "base.field" (list "type" $type "base.string" $typeAllows) }}
  {{- end }}

  {{- /* averageUtilization int */ -}}
  {{- if eq $type "Utilization" }}
    {{- $averageUtilization := include "base.getValue" (list . "averageUtilization") }}
    {{- if $averageUtilization }}
      {{- include "base.field" (list "averageUtilization" $averageUtilization "base.int") }}
    {{- end }}

  {{- /* averageValue Quantity */ -}}
  {{- else if eq $type "AverageValue" }}
    {{- $averageValue := include "base.getValue" (list . "averageValue") }}
    {{- if $averageValue }}
      {{- include "base.field" (list "averageValue" $averageValue "base.Quantity") }}
    {{- end }}

  {{- /* value Quantity */ -}}
  {{- else if eq $type "Value" }}
    {{- $value := include "base.getValue" (list . "value") }}
    {{- if $value }}
      {{- include "base.field" (list "value" $value "base.Quantity") }}
    {{- end }}

  {{- end }}
{{- end }}
