{{- define "definitions.TopologySelectorTerm" -}}
  {{- /* matchLabelExpressions array */ -}}
  {{- $matchLabelExpressionsVal := include "base.getValue" (list . "matchLabelExpressions") | fromYamlArray }}
  {{- $matchLabelExpressions := list }}
  {{- range $matchLabelExpressionsVal }}
    {{- range $k, $v := . }}
      {{- $val := dict "key" $k "values" $v }}
      {{- $matchLabelExpressions = append $matchLabelExpressions (include "definitions.TopologySelectorLabelRequirement" $val | fromYaml) }}
    {{- end }}
  {{- end }}
  {{- $matchLabelExpressions = $matchLabelExpressions | mustUniq | mustCompact }}
  {{- if $matchLabelExpressions }}
    {{- if $matchLabelExpressions }}
      {{- include "base.field" (list "matchLabelExpressions" $matchLabelExpressions "base.slice") }}
    {{- end }}
  {{- end }}
{{- end }}
