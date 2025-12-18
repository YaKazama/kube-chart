{{- define "definitions.NetworkPolicyPort" -}}
  {{- /* endPort int */ -}}
  {{- $endPort := include "base.getValue" (list . "endPort") }}
  {{- if $endPort }}
    {{- include "base.field" (list "endPort" $endPort "base.port") }}
  {{- end }}

  {{- /* port string or int*/ -}}
  {{- $port := include "base.getValue" (list . "port") }}
  {{- $const := include "base.env" "" | fromYaml }}
  {{- if regexMatch $const.net.port $port }}
    {{- include "base.field" (list "port" $port "base.port") }}
  {{- else }}
    {{- include "base.field" (list "port" $port "base.rfc1035") }}
  {{- end }}

  {{- /* protocol string */ -}}
  {{- $protocol := include "base.getValue" (list . "protocol") | upper }}
  {{- $protocolAllows := list "TCP" "UDP" "SCTP" }}
  {{- if $protocol }}
    {{- include "base.field" (list "protocol" $protocol "base.string" $protocolAllows) }}
  {{- end }}
{{- end }}
