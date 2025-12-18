{{- define "definitions.NodeAffinity" -}}
  {{- /* preferredDuringSchedulingIgnoredDuringExecution array */ -}}
  {{- $preferredVal := include "base.getValue" (list . "preferred") | fromYamlArray }}
  {{- $preferred := list }}
  {{- range $preferredVal }}
    {{- $val := dict "weight" (get . "weight") "preference" (pick . "matchExpressions" "matchFields") }}
    {{- $preferred = append $preferred (include "definitions.PreferredSchedulingTerm" $val | fromYaml) }}
  {{- end }}
  {{- $preferred = $preferred | mustUniq | mustCompact }}
  {{- if $preferred }}
    {{- include "base.field" (list "preferredDuringSchedulingIgnoredDuringExecution" $preferred "base.slice") }}
  {{- end }}

  {{- /* requiredDuringSchedulingIgnoredDuringExecution map */ -}}
  {{- $requiredVal := include "base.getValue" (list . "required") | fromYamlArray }}
  {{- $val := dict "nodeSelectorTerms" $requiredVal }}
  {{- $required := include "definitions.NodeSelector" $val | fromYaml }}
  {{- if $required }}
    {{- include "base.field" (list "requiredDuringSchedulingIgnoredDuringExecution" $required "base.map") }}
  {{- end }}
{{- end }}
