{{- define "old.EndpointPort" -}}
  {{- /* appProtocol string */ -}}
  {{- $appProtocol := include "base.getValue" (list . "appProtocol") }}
  {{- if $appProtocol }}
    {{- include "base.field" (list "appProtocol" $appProtocol) }}
  {{- end }}

  {{- /* name string */ -}}
  {{- $name := include "base.getValue" (list . "name") }}
  {{- if $name }}
    {{- include "base.field" (list "name" $name "base.name") }}
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
    {{- include "base.field" (list "protocol" ($protocol | upper) "base.string" $protocolAllows) }}
  {{- end }}
{{- end }}
