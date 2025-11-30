{{- define "definitions.TCPSocketAction" -}}
  {{- $regex := "^(?:(\\S+)\\s+)?(\\d+)$" }}

  {{- $match := regexFindAll $regex . -1 }}
  {{- if not $match }}
    {{- fail (printf "TCPSocketAction: error. Values: %s, format: '[host] port'" .) }}
  {{- end }}

  {{- /* host string */ -}}
  {{- $host := regexReplaceAll $regex . "${1}" }}
  {{- if $host }}
    {{- include "base.field" (list "host" $host) }}
  {{- end }}

  {{- /* port int */ -}}
  {{- $port := regexReplaceAll $regex . "${2}" }}
  {{- if $port }}
    {{- include "base.field" (list "port" $port "base.port") }}
  {{- end }}
{{- end }}
