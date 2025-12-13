{{- define "definitions.GRPCAction" -}}
  {{- $const := include "base.env" "" | fromYaml }}

  {{- $match := regexFindAll $const.regexGRPCAction . -1 }}
  {{- if not $match }}
    {{- fail (printf "GRPCAction: error. Values: %s, format: '[service] port'" .) }}
  {{- end }}

  {{- /* port int */ -}}
  {{- $port := regexReplaceAll $const.regexGRPCAction . "${2}" }}
  {{- if $port }}
    {{- include "base.field" (list "port" $port "base.port") }}
  {{- end }}

  {{- /* service string */ -}}
  {{- $service := regexReplaceAll $const.regexGRPCAction . "${1}" }}
  {{- if $service }}
    {{- include "base.field" (list "service" $service) }}
  {{- end }}
{{- end }}
