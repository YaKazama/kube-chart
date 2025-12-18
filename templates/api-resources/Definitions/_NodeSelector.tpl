{{- define "definitions.NodeSelector" -}}
  {{- /* nodeSelectorTerms */ -}}
  {{- /* 传递的是一个包括 expressions fields 字段的字典 */ -}}
  {{- $nodeSelectorTermsVal := include "base.getValue" (list . "nodeSelectorTerms") | fromYamlArray }}
  {{- $nodeSelectorTerms := list }}
  {{- range $nodeSelectorTermsVal }}
    {{- $val := pick . "matchExpressions" "matchFields" }}
    {{- $nodeSelectorTerms = append $nodeSelectorTerms (include "definitions.NodeSelectorTerm" $val | fromYaml) }}
  {{- end }}
  {{- $nodeSelectorTerms = $nodeSelectorTerms | mustUniq | mustCompact }}
  {{- if $nodeSelectorTerms }}
    {{- include "base.field" (list "nodeSelectorTerms" $nodeSelectorTerms "base.slice") }}
  {{- end }}
{{- end }}
