{{- define "definitions.PreferredSchedulingTerm" -}}
  {{- /* weight int */ -}}
  {{- $weight := default 1 (include "base.getValue" (list . "weight")) }}
  {{- if $weight }}
    {{- include "base.field" (list "weight" (list (int $weight) 1 100) "base.int.range") }}
  {{- end }}

  {{- /* preference map */ -}}
  {{- /* 传递的是一个包括 expressions fields 字段的字典 */ -}}
  {{- $preference := include "definitions.NodeSelectorTerm" . | fromYaml }}
  {{- if $preference }}
    {{- include "base.field" (list "preference" $preference "base.map") }}
  {{- end }}
{{- end }}
