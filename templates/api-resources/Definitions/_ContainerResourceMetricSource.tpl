{{- define "definitions.ContainerResourceMetricSource" -}}
  {{- /* container string */ -}}
  {{- $container := include "base.getValue" (list . "container") }}
  {{- if $container }}
    {{- include "base.field" (list "container" $container) }}
  {{- end }}

  {{- /* name string */ -}}
  {{- $name := include "base.getValue" (list . "name") }}
  {{- if $name }}
    {{- include "base.field" (list "name" $name) }}
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
