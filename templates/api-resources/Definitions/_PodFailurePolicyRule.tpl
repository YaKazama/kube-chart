{{- define "definitions.PodFailurePolicyRule" -}}
  {{- $const := include "base.env" "" | fromYaml }}

  {{- $match1 := regexFindAll $const.regexPodFailurePolicyRule1 . -1 }}
  {{- $match2 := regexFindAll $const.regexPodFailurePolicyRule2 . -1 }}

  {{- if $match1 }}
    {{- /* action string */ -}}
    {{- $action := regexReplaceAll $const.regexPodFailurePolicyRule1 . "${1}" }}
    {{- if $action }}
      {{- include "base.field" (list "action" $action) }}
    {{- end }}

    {{- /* onExitCodes map */ -}}
    {{- $onExitCodes := include "definitions.PodFailurePolicyOnExitCodesRequirement" . | fromYaml }}
    {{- if $onExitCodes }}
      {{- include "base.field" (list "onExitCodes" $onExitCodes "base.map") }}
    {{- end }}

  {{- else if $match2 }}
    {{- /* action string */ -}}
    {{- $action := regexReplaceAll $const.regexPodFailurePolicyRule2 . "${1}" }}
    {{- if $action }}
      {{- include "base.field" (list "action" $action) }}
    {{- end }}

    {{- /* onPodConditions array */ -}}
    {{- $onPodConditionsVal := regexReplaceAll $const.regexPodFailurePolicyRule2 . "${2}" }}
    {{- $onPodConditions := list }}
    {{- $val := include "base.slice.cleanup" (dict "s" $onPodConditionsVal "r" ",\\s*") | fromYamlArray }}
    {{- range $val }}
      {{- $onPodConditions = append $onPodConditions (include "definitions.PodFailurePolicyOnPodConditionsPattern" . | fromYaml) }}
    {{- end }}
    {{- if gt (len $onPodConditions) 20 }}
      {{- $onPodConditions = slice $onPodConditions 0 20 }}
    {{- end }}
    {{- if $onPodConditions }}
      {{- include "base.field" (list "onPodConditions" $onPodConditions "base.slice") }}
    {{- end }}

  {{- else }}
    {{- fail (printf "PodFailurePolicyRule: error. Values: %s, format: onExitCodes: '<action> [containerName] <in|notin> (values, ...)', onPodConditions: '<action> (type [status], ...)'" .) }}
  {{- end }}
{{- end }}
