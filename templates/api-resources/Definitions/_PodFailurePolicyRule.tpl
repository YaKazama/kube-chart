{{- define "definitions.PodFailurePolicyRule" -}}
  {{- $const := include "base.env" "" | fromYaml }}

  {{- /* action string */ -}}
  {{- $action := include "base.getValue" (list . "action") }}
  {{- $actionAllows := list "Count" "FailIndex" "FailJob" "Ignore" }}
  {{- if $action }}
    {{- include "base.field" (list "action" $action "base.string" $actionAllows) }}
  {{- end }}

  {{- /* onExitCodes map */ -}}
  {{- $onExitCodesVal := include "base.getValue" (list . "onExitCodes") }}
  {{- if $onExitCodesVal }}
    {{- $match := regexFindAll $const.k8s.policy.podFailure.exitCodes $onExitCodesVal -1 }}
    {{- if not $match }}
      {{- fail (printf "definitions.PodFailurePolicyRule: onExitCodes invalid. Values: %s, format: '[containerName] <in|notin> (values, ...)'" $onExitCodesVal) }}
    {{- end }}

    {{- $containerName := regexReplaceAll $const.k8s.policy.podFailure.exitCodes $onExitCodesVal "${1}" | trim }}
    {{- $operator := regexReplaceAll $const.k8s.policy.podFailure.exitCodes $onExitCodesVal "${2}" | trim | lower }}
    {{- $values := regexReplaceAll $const.k8s.policy.podFailure.exitCodes $onExitCodesVal "${3}" | trim }}

    {{- if eq $operator "in" }}
      {{- $operator = "In" }}
    {{- else if eq $operator "notin" }}
      {{- $operator = "NotIn" }}
    {{- end }}

    {{- $val := dict "containerName" $containerName "operator" $operator "values" (include "base.slice.cleanup" (dict "s" $values "r" $const.split.comma "c" $const.types.positiveInt)) }}

    {{- $onExitCodes := include "definitions.PodFailurePolicyOnExitCodesRequirement" $val | fromYaml }}
    {{- if $onExitCodes }}
      {{- include "base.field" (list "onExitCodes" $onExitCodes "base.map") }}
    {{- end }}
  {{- end }}

  {{- /* onPodConditions array */ -}}
  {{- $onPodConditionsVal := include "base.getValue" (list . "onPodConditions") }}
  {{- $onPodConditions := list }}
  {{- if $onPodConditionsVal }}
    {{- range regexSplit $const.split.comma $onPodConditionsVal -1 }}
      {{- $match := regexFindAll $const.k8s.policy.podFailure.podConditions . -1 }}
      {{- if not $match }}
        {{- fail (printf "definitions.PodFailurePolicyRule: onPodConditions invalid. Values: %s, format: 'type [status]'" .) }}
      {{- end }}

      {{- $type := regexReplaceAll $const.k8s.policy.podFailure.podConditions . "${1}" | trim }}
      {{- $status := regexReplaceAll $const.k8s.policy.podFailure.podConditions . "${2}" | trim }}
      {{- $val := dict "type" $type "status" $status }}

      {{- $onPodConditions = append $onPodConditions (include "definitions.PodFailurePolicyOnPodConditionsPattern" $val | fromYaml) }}
    {{- end }}
  {{- end }}
  {{- $onPodConditions = $onPodConditions | mustUniq | mustCompact }}
  {{- if gt (len $onPodConditions) 20 }}
    {{- $onPodConditions = slice $onPodConditions 0 20 }}
  {{- end }}
  {{- if $onPodConditions }}
    {{- include "base.field" (list "onPodConditions" $onPodConditions "base.slice") }}
  {{- end }}
{{- end }}
