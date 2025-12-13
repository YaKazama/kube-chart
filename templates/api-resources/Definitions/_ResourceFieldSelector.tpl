{{- define "definitions.ResourceFieldSelector" -}}
  {{- $const := include "base.env" "" | fromYaml }}

  {{- $match := regexFindAll $const.regexResourceFieldSelector . -1 }}
  {{- if not $match }}
    {{- fail (printf "ResourceFieldSelector: error, Values: %s, format: 'resource [containerName] [divisor]'" .) }}
  {{- end }}

  {{- /* containerName string */ -}}
  {{- $containerName := regexReplaceAll $const.regexResourceFieldSelector . "${2}" }}
  {{- if $containerName }}
    {{- include "base.field" (list "containerName" $containerName) }}
  {{- end }}

  {{- /* divisor Quantity */ -}}
  {{- $divisor := regexReplaceAll $const.regexResourceFieldSelector . "${3}" }}
  {{- if and $divisor (gt $divisor "0") }}
    {{- include "base.field" (list "divisor" $divisor "base.Quantity") }}
  {{- end }}

  {{- /* resource string */ -}}
  {{- $resource := regexReplaceAll $const.regexResourceFieldSelector . "${1}" }}
  {{- include "base.field" (list "resource" $resource) }}
{{- end }}
