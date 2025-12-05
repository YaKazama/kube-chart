{{- define "definitions.SuccessPolicy" -}}
  {{- /* rules array */ -}}
  {{- $rules := list }}
  {{- range . }}
    {{- $rules = append $rules (include "definitions.SuccessPolicyRule" . | fromYaml) }}
  {{- end }}
  {{- $rules = $rules | mustUniq | mustCompact }}
  {{- if $rules }}
    {{- include "base.field" (list "rules" $rules "base.slice") }}
  {{- end }}
{{- end }}
