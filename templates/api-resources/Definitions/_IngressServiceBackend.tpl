{{- define "definitions.IngressServiceBackend" -}}
  {{- $const := include "base.env" "" | fromYaml }}

  {{- /* name string */ -}}
  {{- $name := include "base.getValue" (list . "name") }}
  {{- if $name }}
    {{- include "base.field" (list "name" $name) }}
  {{- end }}

  {{- /* port map */ -}}
  {{- $portVal := include "base.getValue" (list . "port") }}
  {{- $val := dict }}
  {{- if regexMatch $const.net.port $portVal }}
    {{- $val = dict "number" $portVal }}
  {{- else }}
    {{- $val = dict "name" $portVal }}
  {{- end }}
  {{- $port := include "definitions.ServiceBackendPort" $val | fromYaml }}
  {{- if $port }}
    {{- include "base.field" (list "port" $port "base.map") }}
  {{- end }}
{{- end }}
