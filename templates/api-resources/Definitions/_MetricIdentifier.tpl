{{- define "definitions.MetricIdentifier" -}}
  {{- /* name string */ -}}
  {{- $name := include "base.getValue" (list . "name") }}
  {{- if $name }}
    {{- include "base.field" (list "name" $name) }}
  {{- end }}

  {{- /* selector map */ -}}
  {{- $selectorVal := include "base.getValue" (list . "selector") | fromYaml }}
  {{- if $selectorVal }}
    {{- $selector := include "definitions.LabelSelector" $selectorVal | fromYaml }}
    {{- if $selector }}
      {{- include "base.field" (list "selector" $selector "base.map") }}
    {{- end }}
  {{- end }}
{{- end }}
