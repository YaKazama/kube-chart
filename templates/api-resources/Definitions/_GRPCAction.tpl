{{- define "definitions.GRPCAction" -}}
  {{- $regex := "^(?:(\\S+)\\s+)?(\\d+)$" }}

  {{- $match := regexFindAll $regex . -1 }}
  {{- if not $match }}
    {{- fail (printf "GRPCAction: error. Values: %s, format: '[service] port'" .) }}
  {{- end }}

  {{- /* port int */ -}}
  {{- $port := regexReplaceAll $regex . "${2}" }}
  {{- if $port }}
    {{- include "base.field" (list "port" $port "base.port") }}
  {{- end }}

  {{- /* service string */ -}}
  {{- $service := regexReplaceAll $regex . "${1}" }}
  {{- if $service }}
    {{- include "base.field" (list "service" $service) }}
  {{- end }}
{{- end }}
