{{- define "definitions.TCPSocketAction" -}}
  {{- $const := include "base.env" "" | fromYaml }}

  {{- $match := regexFindAll $const.regexGRPCAction . -1 }}
  {{- if not $match }}
    {{- fail (printf "TCPSocketAction: error. Values: %s, format: '[host] port'" .) }}
  {{- end }}

  {{- /* host string */ -}}
  {{- $host := regexReplaceAll $const.regexGRPCAction . "${1}" }}
  {{- if $host }}
    {{- include "base.field" (list "host" $host) }}
  {{- end }}

  {{- /* port int */ -}}
  {{- $port := regexReplaceAll $const.regexGRPCAction . "${2}" }}
  {{- if $port }}
    {{- include "base.field" (list "port" $port "base.port") }}
  {{- end }}
{{- end }}
