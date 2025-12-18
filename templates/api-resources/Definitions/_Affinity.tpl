{{- define "definitions.Affinity" -}}
  {{- /* nodeAffinity map */ -}}
  {{- $nodeAffinityVal := include "base.getValue" (list . "nodeAffinity") | fromYaml }}
  {{- if $nodeAffinityVal }}
    {{- $preferred := include "base.getValue" (list $nodeAffinityVal "preferred") | fromYamlArray }}
    {{- $required := include "base.getValue" (list $nodeAffinityVal "required") | fromYamlArray }}
    {{- $val := dict "preferred" $preferred "required" $required }}
    {{- $nodeAffinity := include "definitions.NodeAffinity" $val | fromYaml }}
    {{- if $nodeAffinity }}
      {{- include "base.field" (list "nodeAffinity" $nodeAffinity "base.map") }}
    {{- end }}
  {{- end }}

  {{- /* podAffinity map */ -}}
  {{- $podAffinityVal := include "base.getValue" (list . "podAffinity") | fromYaml }}
  {{- if $podAffinityVal }}
    {{- $preferred := include "base.getValue" (list $podAffinityVal "preferred") | fromYamlArray }}
    {{- $required := include "base.getValue" (list $podAffinityVal "required") | fromYamlArray }}
    {{- $val := dict "preferred" $preferred "required" $required }}
    {{- $podAffinity := include "definitions.PodAffinity" $val | fromYaml }}
    {{- if $podAffinity }}
      {{- include "base.field" (list "podAffinity" $podAffinity "base.map") }}
    {{- end }}
  {{- end }}

  {{- /* podAntiAffinity map */ -}}
  {{- $podAntiAffinityVal := include "base.getValue" (list . "podAntiAffinity") | fromYaml }}
  {{- if $podAntiAffinityVal }}
    {{- $preferred := include "base.getValue" (list $podAntiAffinityVal "preferred") | fromYamlArray }}
    {{- $required := include "base.getValue" (list $podAntiAffinityVal "required") | fromYamlArray }}
    {{- $val := dict "preferred" $preferred "required" $required }}
    {{- $podAntiAffinity := include "definitions.PodAntiAffinity" $val | fromYaml }}
    {{- if $podAntiAffinity }}
      {{- include "base.field" (list "podAntiAffinity" $podAntiAffinity "base.map") }}
    {{- end }}
  {{- end }}
{{- end }}
