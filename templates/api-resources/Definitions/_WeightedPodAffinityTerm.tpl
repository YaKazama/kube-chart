{{- define "definitions.WeightedPodAffinityTerm" -}}
  {{- /* weight int */ -}}
  {{- $weight := default 1 (include "base.getValue" (list . "weight")) }}
  {{- if $weight }}
    {{- include "base.field" (list "weight" (list (int $weight) 1 100) "base.int.range") }}
  {{- end }}

  {{- /* podAffinityTerm map */ -}}
  {{- $podAffinityTermVal := include "base.getValue" (list . "podAffinityTerm") | fromYaml }}
  {{- $podAffinityTerm := include "definitions.PodAffinityTerm" $podAffinityTermVal | fromYaml }}
  {{- if $podAffinityTerm }}
    {{- include "base.field" (list "podAffinityTerm" $podAffinityTerm "base.map") }}
  {{- end }}
{{- end }}
