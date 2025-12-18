{{- define "definitions.PodFailurePolicy" -}}
  {{- $const := include "base.env" "" | fromYaml }}

  {{- /* rules array */ -}}
  {{- $rulesVal := include "base.getValue" (list . "rules") | fromYamlArray }}
  {{- $rules := list }}
  {{- range $rulesVal }}
    {{- $match1 := regexFindAll $const.k8s.policy.podFailure.rules0 . -1 }}
    {{- $match2 := regexFindAll $const.k8s.policy.podFailure.rules1 . -1 }}

    {{- $val := dict }}
    {{- if $match1 }}
      {{- $action := regexReplaceAll $const.k8s.policy.podFailure.rules0 . "${1}" | trim }}
      {{- $onExitCodes := regexReplaceAll $const.k8s.policy.podFailure.rules0 . "${2} ${3} (${4})" | trim }}
      {{- $val = dict "action" $action "onExitCodes" $onExitCodes }}

    {{- else if $match2 }}
      {{- $action := regexReplaceAll $const.k8s.policy.podFailure.rules1 . "${1}" }}
      {{- $onPodConditions := regexReplaceAll $const.k8s.policy.podFailure.rules1 . "${2}" }}
      {{- $val = dict "action" $action "onPodConditions" $onPodConditions }}

    {{- else }}
      {{- fail (printf "definitions.PodFailurePolicy: rules invalid. Values: '%s', format: onExitCodes: '<action> [containerName] <in|notin> (values, ...)', onPodConditions: '<action> (type [status], ...)'") }}
    {{- end }}

    {{- $rules = append $rules (include "definitions.PodFailurePolicyRule" $val | fromYaml) }}
  {{- end }}
  {{- $rules = $rules | mustUniq | mustCompact }}
  {{- if gt (len $rules) 20 }}
    {{- $rules = slice $rules 0 20 }}
  {{- end }}
  {{- if $rules }}
    {{- include "base.field" (list "rules" $rules "base.slice") }}
  {{- end }}
{{- end }}
