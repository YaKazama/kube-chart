{{- define "definitions.ResourceFieldSelector" -}}
  {{- $regex := "^resource\\s+(\\S+)(?:\\s+(\\S+))?(?:\\s+(\\S+))?$" }}

  {{- $match := regexFindAll $regex . -1 }}
  {{- if not $match }}
    {{- fail (printf "ResourceFieldSelector: error, Values: %s, format: 'resource [containerName] [divisor]'" .) }}
  {{- end }}

  {{- /* containerName string */ -}}
  {{- $containerName := regexReplaceAll $regex . "${2}" }}
  {{- if $containerName }}
    {{- include "base.field" (list "containerName" $containerName) }}
  {{- end }}

  {{- /* divisor Quantity */ -}}
  {{- $divisor := regexReplaceAll $regex . "${3}" }}
  {{- if and $divisor (gt $divisor "0") }}
    {{- include "base.field" (list "divisor" $divisor "base.Quantity") }}
  {{- end }}

  {{- /* resource string */ -}}
  {{- $resource := regexReplaceAll $regex . "${1}" }}
  {{- include "base.field" (list "resource" $resource) }}
{{- end }}
