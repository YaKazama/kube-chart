{{- define "definitions.PodFailurePolicyOnExitCodesRequirement" -}}
  {{- $const := include "base.env" "" | fromYaml }}

  {{- $match := regexFindAll $const.regexPodFailurePolicyOnExitCodesRequirement . -1 }}
  {{- if not $match }}
    {{- fail (printf "PodFailurePolicyOnExitCodesRequirement: error. Values: %s, format: '<action> [containerName] <in|notin> (values, ...)'" .) }}
  {{- end }}

  {{- /* contaerinName string */ -}}
  {{- $contaerinName := regexReplaceAll $const.regexPodFailurePolicyOnExitCodesRequirement . "${2}" }}
  {{- if $contaerinName }}
    {{- include "base.field" (list "contaerinName" $contaerinName) }}
  {{- end }}

  {{- /* operator string */ -}}
  {{- $operator := regexReplaceAll $const.regexPodFailurePolicyOnExitCodesRequirement . "${3}" }}
  {{- if $operator }}
    {{- if eq $operator "in" }}
      {{- $operator = "In" }}
    {{- else if eq $operator "notin" }}
      {{- $operator = "NotIn" }}
    {{- end }}
    {{- include "base.field" (list "operator" $operator) }}
  {{- end }}

  {{- /* values int array */ -}}
  {{- $values := regexReplaceAll $const.regexPodFailurePolicyOnExitCodesRequirement . "${4}" }}
  {{- if not (regexMatch $const.regexPodFailurePolicyOnExitCodesRequirementValues $values) }}
    {{- fail (printf "PodFailurePolicyOnExitCodesRequirement: values invalid. Values: '%s'" $values) }}
  {{- end }}
  {{- $checkValues := regexSplit ",\\s*" $values -1 }}
  {{- if and (mustHas "0" $checkValues) (eq $operator "In") }}
    {{- fail "PodFailurePolicyOnExitCodesRequirement: Value '0' cannot be used for the In operator" }}
  {{- end }}
  {{- if $values }}
    {{- include "base.field" (list "values" (dict "s" $values "r" ",\\s*" "empty" true) "base.slice.cleanup") }}
  {{- end }}
{{- end }}
