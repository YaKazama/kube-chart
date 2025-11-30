{{- /*
  数据格式：
    - .(顶层上下文)
*/ -}}
{{- define "definitions.Affinity" -}}
  {{- /* nodeAffinity map */ -}}
  {{- $nodeAffinityVal := include "base.getValue" (list . "nodeAffinity") | fromYaml }}
  {{- $nodeAffinity := include "definitions.NodeAffinity" $nodeAffinityVal | fromYaml }}
  {{- if $nodeAffinity }}
    {{- include "base.field" (list "nodeAffinity" $nodeAffinity "base.map") }}
  {{- end }}

  {{- /* podAffinity map */ -}}
  {{- $podAffinityVal := include "base.getValue" (list . "podAffinity") | fromYaml }}
  {{- $podAffinity := include "definitions.PodAffinity" $podAffinityVal | fromYaml }}
  {{- if $podAffinity }}
    {{- include "base.field" (list "podAffinity" $podAffinity "base.map") }}
  {{- end }}

  {{- /* podAntiAffinity map */ -}}
  {{- $podAntiAffinityVal := include "base.getValue" (list . "podAntiAffinity") | fromYaml }}
  {{- $podAntiAffinity := include "definitions.PodAntiAffinity" $podAntiAffinityVal | fromYaml }}
  {{- if $podAntiAffinity }}
    {{- include "base.field" (list "podAntiAffinity" $podAntiAffinity "base.map") }}
  {{- end }}
{{- end }}
