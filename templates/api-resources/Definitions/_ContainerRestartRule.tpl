{{- define "definitions.ContainerRestartRule" -}}
  {{- $const := include "base.env" "" | fromYaml }}

  {{- $match := regexFindAll $const.regexContainerRestartRule . -1 }}
  {{- if not $match }}
    {{- fail (printf "definitions.ContainerRestartRule: error. Values: %s, format: 'restart <in|notin> (codeNumber, ...)'" .) }}
  {{- end }}

  {{- /* action string */ -}}
  {{- $action := regexReplaceAll $const.regexContainerRestartRule . "${1}" | trim | title }}
  {{- include "base.field" (list "action" $action) }}

  {{- /* exitCodes map */ -}}
  {{- $operator := regexReplaceAll $const.regexContainerRestartRule . "${2}" | trim }}
  {{- $values := regexReplaceAll $const.regexContainerRestartRule . "${3}" | trim }}

  {{- if eq $operator "in" }}
    {{- $operator = "In" }}
  {{- else if eq $operator "notin" }}
    {{- $operator = "NotIn" }}
  {{- end }}

  {{- $exitCodesVal := dict "operator" $operator "values" (include "base.slice.cleanup" (dict "s" $values "r" ",\\s*" "c" "^\\d+$") | fromYamlArray) }}
  {{- $exitCodes := include "definitions.ContainerRestartRuleOnExitCodes" $exitCodesVal | fromYaml }}
  {{- if $exitCodes }}
    {{- include "base.field" (list "exitCodes" $exitCodes "base.map") }}
  {{- end }}
{{- end }}
