{{- define "definitions.ObjectMetricSource" -}}
  {{- /* describedObject map */ -}}
  {{- $describedObjectVal := include "base.getValue" (list . "describedObject") | fromYaml }}
  {{- if $describedObjectVal }}
    {{- $describedObject := include "definitions.CrossVersionObjectReference" $describedObjectVal | fromYaml }}
    {{- if $describedObject }}
      {{- include "base.field" (list "describedObject" $describedObject "base.map") }}
    {{- end }}
  {{- end }}

  {{- /* metric map */ -}}
  {{- $metricVal := include "base.getValue" (list . "metric") | fromYaml }}
  {{- if $metricVal }}
    {{- $metric := include "definitions.MetricIdentifier" $metricVal | fromYaml }}
    {{- if $metric }}
      {{- include "base.field" (list "metric" $metric "base.map") }}
    {{- end }}
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
