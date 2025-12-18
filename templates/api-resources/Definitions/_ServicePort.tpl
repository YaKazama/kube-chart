{{- define "definitions.ServicePort" -}}
  {{- /* appProtocol string */ -}}
  {{- $appProtocol := include "base.getValue" (list . "appProtocol") }}
  {{- if $appProtocol }}
    {{- include "base.field" (list "appProtocol" $appProtocol) }}
  {{- end }}

  {{- /* name string */ -}}
  {{- $name := include "base.getValue" (list . "name") }}
  {{- $_port := include "base.getValue" (list . "port") }}
  {{- $_targetPort := include "base.getValue" (list . "targetPort") }}
  {{- $_protocol := include "base.getValue" (list . "protocol") | lower }}
  {{- include "base.field" (list "name" (coalesce $name (printf "%s-%s-%s-%s" (coalesce $_protocol "tcp") $_port (coalesce $_targetPort $_port) (randAlpha 8 | lower)))) }}

  {{- /* nodePort int */ -}}
  {{- $nodePort := include "base.getValue" (list . "nodePort") }}
  {{- if $nodePort }}
    {{- include "base.field" (list "nodePort" $nodePort "base.port") }}
  {{- end }}

  {{- /* port int */ -}}
  {{- $port := include "base.getValue" (list . "port") }}
  {{- if $port }}
    {{- include "base.field" (list "port" $port "base.port") }}
  {{- end }}

  {{- /* protocol string */ -}}
  {{- $protocol := include "base.getValue" (list . "protocol") | upper }}
  {{- $protocolAllows := list "TCP" "UDP" "SCTP" }}
  {{- if $protocol }}
    {{- include "base.field" (list "protocol" $protocol "base.string" $protocolAllows) }}
  {{- end }}

  {{- /* targetPort int or string */ -}}
  {{- $targetPort := include "base.getValue" (list . "targetPort") }}
  {{- if $targetPort }}
    {{- $const := include "base.env" "" | fromYaml }}
    {{- if regexMatch $const.net.port $targetPort }}
      {{- include "base.field" (list "targetPort" $targetPort "base.port") }}
    {{- else }}
      {{- include "base.field" (list "targetPort" $targetPort) }}
    {{- end }}
  {{- else }}
    {{- include "base.field" (list "targetPort" $port "base.port") }}
  {{- end }}
{{- end }}
