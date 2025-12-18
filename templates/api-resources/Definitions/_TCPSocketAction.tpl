{{- define "definitions.TCPSocketAction" -}}
  {{- /* host string */ -}}
  {{- $host := include "base.getValue" (list . "host") }}
  {{- if $host }}
    {{- include "base.field" (list "host" $host "base.dns") }}
  {{- end }}

  {{- /* port int */ -}}
  {{- $port := include "base.getValue" (list . "port") }}
  {{- if $port }}
    {{- include "base.field" (list "port" $port "base.port") }}
  {{- end }}
{{- end }}
