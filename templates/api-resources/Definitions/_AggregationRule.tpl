{{- define "definitions.AggregationRule" -}}
  {{- /* clusterRoleSelectors array */ -}}
  {{- $clusterRoleSelectorsVal := include "base.getValue" (list . "clusterRoleSelectors") | fromYamlArray }}
  {{- $clusterRoleSelectors := list }}
  {{- range $clusterRoleSelectorsVal }}
    {{- $clusterRoleSelectors = append $clusterRoleSelectors (include "definitions.LabelSelector" . | fromYaml) }}
  {{- end }}
  {{- $clusterRoleSelectors = $clusterRoleSelectors | mustUniq | mustCompact }}
  {{- if $clusterRoleSelectors }}
    {{- include "base.field" (list "clusterRoleSelectors" $clusterRoleSelectors "base.slice") }}
  {{- end }}
{{- end }}
