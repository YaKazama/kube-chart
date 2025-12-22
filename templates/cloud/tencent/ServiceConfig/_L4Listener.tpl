{{- define "serviceConfig.L4Listener" -}}
  {{- /* protocol string */ -}}
  {{- $protocol := include "base.getValue" (list . "protocol") }}
  {{- $protocolAllows := list "TCP" "UDP" "TCP_SSL" "QUIC" }}
  {{- if $protocol }}
    {{- include "base.field" (list "protocol" ($protocol | upper) "base.string" $protocolAllows) }}
  {{- end }}

  {{- /* port int */ -}}
  {{- $port := include "base.getValue" (list . "port") }}
  {{- if $port }}
    {{- include "base.field" (list "port" $port "base.port") }}
  {{- end }}

  {{- /* deregisterTargetRst bool */ -}}
  {{- $deregisterTargetRst := include "base.getValue" (list . "deregisterTargetRst") }}
  {{- if $deregisterTargetRst }}
    {{- include "base.field" (list "deregisterTargetRst" $deregisterTargetRst "base.bool") }}
  {{- end }}

  {{- /* session map */ -}}
  {{- $sessionVal := include "base.getValue" (list . "session") | fromYaml }}
  {{- if $sessionVal }}
    {{- $session := include "serviceConfig.Session" $sessionVal | fromYaml }}
    {{- if $session }}
      {{- include "base.field" (list "session" $session "base.map") }}
    {{- end }}
  {{- end }}

  {{- /* healthCheck map */ -}}
  {{- $healthCheckVal := include "base.getValue" (list . "healthCheck") | fromYaml }}
  {{- if $healthCheckVal }}
    {{- $healthCheck := include "serviceConfig.HealthCheck" $healthCheckVal | fromYaml }}
    {{- if $healthCheck }}
      {{- include "base.field" (list "healthCheck" $healthCheck "base.map") }}
    {{- end }}
  {{- end }}

  {{- /* scheduler string */ -}}
  {{- $scheduler := include "base.getValue" (list . "scheduler") }}
  {{- $schedulerAllows := list "WRR" "LEAST_CONN" }}
  {{- if $scheduler }}
    {{- include "base.field" (list "scheduler" ($scheduler | upper) "base.string" $schedulerAllows) }}
  {{- end }}

  {{- /* proxyProtocol map */ -}}
  {{- $proxyProtocolVal := include "base.getValue" (list . "proxyProtocol") | fromYaml }}
  {{- if $proxyProtocolVal }}
    {{- $proxyProtocol := include "serviceConfig.Proxy" $proxyProtocolVal | fromYaml }}
    {{- if $proxyProtocol }}
      {{- include "base.field" (list "proxyProtocol" $proxyProtocol "base.map") }}
    {{- end }}
  {{- end }}
{{- end }}
