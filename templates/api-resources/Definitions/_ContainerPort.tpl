{{- define "definitions.ContainerPort" -}}
  {{- /* containerPort int */ -}}
  {{- $containerPort := include "base.getValue" (list . "containerPort") }}
  {{- if $containerPort }}
    {{- include "base.field" (list "containerPort" $containerPort "base.port") }}
  {{- end }}

  {{- /* hostIP string */ -}}
  {{- $hostIP := include "base.getValue" (list . "hostIP") }}
  {{- if $hostIP }}
    {{- include "base.field" (list "hostIP" $hostIP "base.ip") }}
  {{- end }}

  {{- /* hostPort int */ -}}
  {{- $hostPort := include "base.getValue" (list . "hostPort") }}
  {{- if $hostPort }}
    {{- include "base.field" (list "hostPort" $hostPort "base.port") }}
  {{- end }}

  {{- /* name string */ -}}
  {{- $name := include "base.getValue" (list . "name") }}
  {{- if $name }}
    {{- include "base.field" (list "name" $name "base.rfc1035") }}
  {{- end }}

  {{- /* protocol */ -}}
  {{- $protocol := include "base.getValue" (list . "protocol") }}
  {{- $protocolAllows := list "TCP" "UDP" "SCTP" }}
  {{- if $protocol }}
    {{- include "base.field" (list "protocol" $protocol "base.string" $protocolAllows) }}
  {{- end }}
{{- end }}
