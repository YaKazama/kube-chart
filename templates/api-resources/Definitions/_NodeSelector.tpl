{{- define "definitions.NodeSelector" -}}
  {{- /* nodeSelectorTerms */ -}}
  {{- /* 传递的是一个包括 expressions fields 字段的字典 */ -}}
  {{- $nodeSelectorTerms := list }}
  {{- range . }}
    {{- $nodeSelectorTerms = append $nodeSelectorTerms (include "definitions.NodeSelectorTerm" . | fromYaml) }}
  {{- end }}
  {{- if $nodeSelectorTerms }}
    {{- include "base.field" (list "nodeSelectorTerms" $nodeSelectorTerms "base.slice") }}
  {{- end }}
{{- end }}
