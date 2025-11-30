{{- define "definitions.ContainerRestartRule" -}}
  {{- $regex := "^([r|R]estart)\\s+(in|notin)\\s+\\((.*?)\\)$" }}

  {{- $match := regexFindAll $regex . -1 }}
  {{- if not $match }}
    {{- fail (printf "configMap: error. Values: %s, format: 'restart <in|notin> (codeNumber, ...)'" .) }}
  {{- end }}

  {{- /* action string */ -}}
  {{- $action := regexReplaceAll $regex . "${1}" | trim | title }}
  {{- include "base.field" (list "action" $action) }}

  {{- /* exitCodes map */ -}}
  {{- $operator := regexReplaceAll $regex . "${2}" | trim }}
  {{- $values := regexReplaceAll $regex . "${3}" | trim }}

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
