{{- define "definitions.SuccessPolicy" -}}
  {{- $const := include "base.env" "" | fromYaml }}

  {{- /* rules array */ -}}
  {{- $rulesVal := include "base.getValue" (list . "rules") | fromYamlArray }}
  {{- $rules := list }}
  {{- range $rulesVal }}
    {{- $val := dict }}
    {{- if kindIs "float64" . }}
      {{- $val = dict "succeededCount" . }}

    {{- else if kindIs "string" . }}
      {{- $match := regexFindAll $const.k8s.policy.success.rules . -1 }}
      {{- if not $match }}
        {{- fail (printf "definitions.SuccessPolicy: SuccessPolicyRule invalid. Values: '%s', format: '[succeededCount] [succeededIndexes]'" .) }}
      {{- end }}

      {{- $succeededCount := regexReplaceAll $const.k8s.policy.success.rules . "${1}" | trim }}
      {{- $succeededIndexes := regexReplaceAll $const.k8s.policy.success.rules . "${2}" | trim }}
      {{- $val = dict "succeededCount" $succeededCount "succeededIndexes" $succeededIndexes }}

    {{- else if kindIs "map" . }}
      {{- $val = pick . "succeededCount" "succeededIndexes" }}
    {{- end }}

    {{- $rules = append $rules (include "definitions.SuccessPolicyRule" $val | fromYaml) }}
  {{- end }}
  {{- $rules = $rules | mustUniq | mustCompact }}
  {{- if gt (len $rules) 20 }}
    {{- $rules = slice $rules 0 20 }}
  {{- end }}
  {{- if $rules }}
    {{- include "base.field" (list "rules" $rules "base.slice") }}
  {{- end }}
{{- end }}
