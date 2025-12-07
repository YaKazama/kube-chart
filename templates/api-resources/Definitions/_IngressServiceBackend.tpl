{{- define "definitions.IngressServiceBackend" -}}
  {{- /* name string */ -}}
  {{- $name := include "base.getValue" (list . "name") }}
  {{- if $name }}
    {{- include "base.field" (list "name" $name) }}
  {{- end }}

  {{- /* port map */ -}}
  {{- $const := include "base.env" "" | fromYaml }}
  {{- $portVal := include "base.getValue" (list . "port") }}
  {{- $_port := dict }}
  {{- if regexMatch $const.regexPort $portVal }}
    {{- $_ := set $_port "number" $portVal }}
  {{- else }}
    {{- $_ := set $_port "name" $portVal }}
  {{- end }}
  {{- $port := include "definitions.ServiceBackendPort" $_port | fromYaml }}
  {{- if $port }}
    {{- include "base.field" (list "port" $port "base.map") }}
  {{- end }}
{{- end }}
