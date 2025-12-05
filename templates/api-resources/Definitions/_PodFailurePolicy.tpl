{{- define "definitions.PodFailurePolicy" -}}
  {{- /* rules array */ -}}
  {{- $rules := list }}
  {{- range . }}
    {{- $rules = append $rules (include "definitions.PodFailurePolicyRule" . | fromYaml) }}
  {{- end }}
  {{- $rules = $rules | mustUniq | mustCompact }}
  {{- if $rules }}
    {{- include "base.field" (list "rules" $rules "base.slice") }}
  {{- end }}
{{- end }}
