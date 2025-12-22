{{- define "definitions.ResourceMetricSource" -}}
  {{- /* name string */ -}}
  {{- $name := include "base.getValue" (list . "name") }}
  {{- $nameAllows := list "cpu" "memory" }}
  {{- if $name }}
    {{- include "base.field" (list "name" $name "base.string" $nameAllows) }}
  {{- end }}

  {{- /* target map */ -}}
  {{- $targetVal := include "base.getValue" (list . "target") | fromYaml }}
  {{- if $targetVal }}
    {{- $target := include "definitions.MetricTarget" $targetVal | fromYaml }}
    {{- if $target }}
      {{- include "base.field" (list "target" $target "base.map") }}
    {{- end }}
  {{- end }}
{{- end }}
