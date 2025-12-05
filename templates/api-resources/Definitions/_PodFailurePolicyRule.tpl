{{- define "definitions.PodFailurePolicyRule" -}}
  {{- $regex1 := "^(FailJob|FailIndex|Ignore|Count)(?:\\s+(\\S+))?(?:\\s+(in|notin))(?:\\s+\\((.*?)\\))$" }}
  {{- $regex2 := "^(FailJob|FailIndex|Ignore|Count)(?:\\s+\\((.*?)\\))$" }}

  {{- $match1 := regexFindAll $regex1 . -1 }}
  {{- $match2 := regexFindAll $regex2 . -1 }}

  {{- if $match1 }}
    {{- /* action string */ -}}
    {{- $action := regexReplaceAll $regex1 . "${1}" }}
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
    {{- $action := regexReplaceAll $regex2 . "${1}" }}
    {{- if $action }}
      {{- include "base.field" (list "action" $action) }}
    {{- end }}

    {{- /* onPodConditions array */ -}}
    {{- $onPodConditionsVal := regexReplaceAll $regex2 . "${2}" }}
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
