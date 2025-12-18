{{- define "definitions.PodAntiAffinity" -}}
  {{- /* preferredDuringSchedulingIgnoredDuringExecution array */ -}}
  {{- $preferredVal := include "base.getValue" (list . "preferred") | fromYamlArray }}
  {{- $preferred := list }}
  {{- range $preferredVal }}
    {{- $val := dict "weight" (get . "weight") "podAffinityTerm" (pick . "labelSelector" "matchLabelKeys" "mismatchLabelKeys" "namespaceSelector" "namespaces" "topologyKey") }}
    {{- $preferred = append $preferred (include "definitions.WeightedPodAffinityTerm" $val | fromYaml) }}
  {{- end }}
  {{- $preferred = $preferred | mustUniq | mustCompact }}
  {{- if $preferred }}
    {{- include "base.field" (list "preferredDuringSchedulingIgnoredDuringExecution" $preferred "base.slice") }}
  {{- end }}

  {{- /* requiredDuringSchedulingIgnoredDuringExecution array */ -}}
  {{- $requiredVal := include "base.getValue" (list . "required") | fromYamlArray }}
  {{- $required := list }}
  {{- range $requiredVal }}
    {{- $val := pick . "labelSelector" "matchLabelKeys" "mismatchLabelKeys" "namespaceSelector" "namespaces" "topologyKey" }}
    {{- $required = append $required (include "definitions.PodAffinityTerm" $val | fromYaml) }}
  {{- end }}
  {{- $required = $required | mustUniq | mustCompact }}
  {{- if $required }}
    {{- include "base.field" (list "requiredDuringSchedulingIgnoredDuringExecution" $required "base.slice") }}
  {{- end }}
{{- end }}
