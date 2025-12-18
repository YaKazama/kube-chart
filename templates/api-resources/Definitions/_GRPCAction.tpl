{{- define "definitions.GRPCAction" -}}
  {{- /* port int */ -}}
  {{- $port := include "base.getValue" (list . "port") }}
  {{- if $port }}
    {{- include "base.field" (list "port" $port "base.port") }}
  {{- end }}

  {{- /* service string */ -}}
  {{- $service := include "base.getValue" (list . "service") }}
  {{- if $service }}
    {{- include "base.field" (list "service" $service) }}
  {{- end }}
{{- end }}
