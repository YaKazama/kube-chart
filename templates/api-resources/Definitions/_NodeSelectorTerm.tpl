{{- define "definitions.NodeSelectorTerm" -}}
  {{- /* matchExpressions array */ -}}
  {{- $matchExpressionsVal := include "base.getValue" (list . "matchExpressions") | fromYamlArray }}
  {{- $matchExpressions := list }}
  {{- range $matchExpressionsVal }}
    {{- $matchExpressions = append $matchExpressions (include "definitions.NodeSelectorRequirement" . | fromYaml) }}
  {{- end }}
  {{- $matchExpressions = $matchExpressions | mustUniq | mustCompact }}
  {{- if $matchExpressions }}
    {{- include "base.field" (list "matchExpressions" $matchExpressions "base.slice") }}
  {{- end }}

  {{- /* matchFields array */ -}}
  {{- $matchFieldsVal := include "base.getValue" (list . "matchFields") | fromYamlArray }}
  {{- $matchFields := list }}
  {{- range $matchFieldsVal }}
    {{- $matchFields = append $matchFields (include "definitions.NodeSelectorRequirement" . | fromYaml) }}
  {{- end }}
  {{- $matchFields = $matchFields | mustUniq | mustCompact }}
  {{- if $matchFields }}
    {{- include "base.field" (list "matchFields" $matchFields "base.slice") }}
  {{- end }}
{{- end }}
