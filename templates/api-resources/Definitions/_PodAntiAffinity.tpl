{{- define "definitions.PodAntiAffinity" -}}
  {{- /* preferredDuringSchedulingIgnoredDuringExecution array */ -}}
  {{- $preferredDuringSchedulingIgnoredDuringExecutionVal := include "base.getValue" (list . "preferred") | fromYamlArray }}
  {{- $preferredDuringSchedulingIgnoredDuringExecution := list }}
  {{- range $preferredDuringSchedulingIgnoredDuringExecutionVal }}
    {{- $preferredDuringSchedulingIgnoredDuringExecution = append $preferredDuringSchedulingIgnoredDuringExecution (include "definitions.WeightedPodAffinityTerm" . | fromYaml) }}
  {{- end }}
  {{- if $preferredDuringSchedulingIgnoredDuringExecution }}
    {{- include "base.field" (list "preferredDuringSchedulingIgnoredDuringExecution" $preferredDuringSchedulingIgnoredDuringExecution "base.slice") }}
  {{- end }}

  {{- /* requiredDuringSchedulingIgnoredDuringExecution array */ -}}
  {{- $requiredDuringSchedulingIgnoredDuringExecutionVal := include "base.getValue" (list . "required") | fromYamlArray }}
  {{- $requiredDuringSchedulingIgnoredDuringExecution := list }}
  {{- range $requiredDuringSchedulingIgnoredDuringExecutionVal }}
    {{- $requiredDuringSchedulingIgnoredDuringExecution = append $requiredDuringSchedulingIgnoredDuringExecution (include "definitions.PodAffinityTerm" . | fromYaml) }}
  {{- end }}
  {{- if $requiredDuringSchedulingIgnoredDuringExecution }}
    {{- include "base.field" (list "requiredDuringSchedulingIgnoredDuringExecution" $requiredDuringSchedulingIgnoredDuringExecution "base.slice") }}
  {{- end }}
{{- end }}
