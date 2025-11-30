{{- define "definitions.Probe" -}}
  {{- /* exec map */ -}}
  {{- $execVal := include "base.getValue" (list . "exec") | fromYamlArray }}
  {{- if $execVal }}
    {{- $exec := include "definitions.ExecAction" $execVal | fromYaml }}
    {{- if $exec }}
      {{- include "base.field" (list "exec" $exec "base.map") }}
    {{- end }}
  {{- end }}

  {{- /* failureThreshold int */ -}}
  {{- $failureThreshold := include "base.getValue" (list . "failureThreshold") }}
  {{- if $failureThreshold }}
    {{- include "base.field" (list "failureThreshold" $failureThreshold "base.int") }}
  {{- end }}

  {{- /* grpc map */ -}}
  {{- $grpcVal := include "base.getValue" (list . "grpc") }}
  {{- if $grpcVal }}
    {{- $grpc := include "definitions.GRPCAction" $grpcVal | fromYaml }}
    {{- if $grpc }}
      {{- include "base.field" (list "grpc" $grpc "base.map") }}
    {{- end }}
  {{- end }}

  {{- /* httpGet map */ -}}
  {{- $httpGetVal := include "base.getValue" (list . "httpGet") }}
  {{- if $httpGetVal }}
    {{- $httpGet := include "definitions.HTTPGetAction" $httpGetVal | fromYaml }}
    {{- if $httpGet }}
      {{- include "base.field" (list "httpGet" $httpGet "base.map") }}
    {{- end }}
  {{- end }}

  {{- /* initialDelaySeconds int */ -}}
  {{- $initialDelaySeconds := include "base.getValue" (list . "initialDelaySeconds") }}
  {{- if $initialDelaySeconds }}
    {{- include "base.field" (list "initialDelaySeconds" $initialDelaySeconds "base.int") }}
  {{- end }}

  {{- /* periodSeconds int */ -}}
  {{- $periodSeconds := include "base.getValue" (list . "periodSeconds") }}
  {{- if $periodSeconds }}
    {{- include "base.field" (list "periodSeconds" $periodSeconds "base.int") }}
  {{- end }}

  {{- /* successThreshold int */ -}}
  {{- $successThreshold := include "base.getValue" (list . "successThreshold") }}
  {{- $_type := include "base.getValue" (list . "_type") }}
  {{- if and $successThreshold (ne $_type "liveness") (ne $_type "startup") }}
    {{- include "base.field" (list "successThreshold" $successThreshold "base.int") }}
  {{- end }}

  {{- /* tcpSocket map */ -}}
  {{- $tcpSocketVal := include "base.getValue" (list . "tcpSocket") }}
  {{- if $tcpSocketVal }}
    {{- $tcpSocket := include "definitions.TCPSocketAction" $tcpSocketVal | fromYaml }}
    {{- if $tcpSocket }}
      {{- include "base.field" (list "tcpSocket" $tcpSocket "base.map") }}
    {{- end }}
  {{- end }}

  {{- /* terminationGracePeriodSeconds int */ -}}
  {{- $terminationGracePeriodSeconds := include "base.getValue" (list . "terminationGracePeriodSeconds") }}
  {{- if $terminationGracePeriodSeconds }}
    {{- include "base.field" (list "terminationGracePeriodSeconds" $terminationGracePeriodSeconds "base.int") }}
  {{- end }}

  {{- /* timeoutSeconds int */ -}}
  {{- $timeoutSeconds := include "base.getValue" (list . "timeoutSeconds") }}
  {{- if $timeoutSeconds }}
    {{- include "base.field" (list "timeoutSeconds" $timeoutSeconds "base.int") }}
  {{- end }}
{{- end }}
