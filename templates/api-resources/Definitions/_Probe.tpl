{{- define "definitions.Probe" -}}
  {{- $const := include "base.env" "" | fromYaml }}

  {{- /* exec map */ -}}
  {{- $execVal := include "base.getValue" (list . "exec") | fromYamlArray }}
  {{- if $execVal }}
    {{- $val := dict "command" $execVal }}
    {{- $exec := include "definitions.ExecAction" $val | fromYaml }}
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
    {{- $match := regexFindAll $const.k8s.container.grpc $grpcVal -1 }}
    {{- if not $match }}
      {{- fail (printf "definitions.Probe: grpc invalid. Values: %s, format: '[service] port'" .) }}
    {{- end }}

    {{- $service := regexReplaceAll $const.k8s.container.grpc $grpcVal "${1}" | trim }}
    {{- $port := regexReplaceAll $const.k8s.container.grpc $grpcVal "${2}" | trim }}
    {{- $val := dict "service" $service "port" $port }}

    {{- $grpc := include "definitions.GRPCAction" $val | fromYaml }}
    {{- if $grpc }}
      {{- include "base.field" (list "grpc" $grpc "base.map") }}
    {{- end }}
  {{- end }}

  {{- /* httpGet map */ -}}
  {{- $httpGetVal := include "base.getValue" (list . "httpGet") }}
  {{- if $httpGetVal }}
    {{- $match := regexFindAll $const.k8s.container.httpGet $httpGetVal -1 }}
    {{- if not $match }}
      {{- fail (printf "definitions.Prob: httpGet invalid, Values: '%s', format: '[sheme] [host] [port] path <header|headers> (name value, ...)'" $httpGetVal) }}
    {{- end }}

    {{- $scheme := regexReplaceAll $const.k8s.container.httpGet $httpGetVal "${1}" | trim | upper }}
    {{- $host := regexReplaceAll $const.k8s.container.httpGet $httpGetVal "${2}" | trim }}
    {{- $port := regexReplaceAll $const.k8s.container.httpGet $httpGetVal "${3}" | trim }}
    {{- $path := regexReplaceAll $const.k8s.container.httpGet $httpGetVal "${4}" | trim }}
    {{- $httpHeaders := regexReplaceAll $const.k8s.container.httpGet $httpGetVal "${6}" }}
    {{- $val := dict "scheme" $scheme "host" $host "port" $port "httpHeaders" $httpHeaders }}

    {{- $httpGet := include "definitions.HTTPGetAction" $val | fromYaml }}
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
    {{- $match := regexFindAll $const.k8s.container.tcpSocket $tcpSocketVal -1 }}
    {{- if not $match }}
      {{- fail (printf "definitions.Probe: tcpSocket invalid. Values: %s, format: '[host] port'" .) }}
    {{- end }}

    {{- $host := regexReplaceAll $const.k8s.container.tcpSocket $tcpSocketVal "${1}" | trim }}
    {{- $port := regexReplaceAll $const.k8s.container.tcpSocket $tcpSocketVal "${2}" | trim }}
    {{- $val := dict "host" $host "port" $port }}

    {{- $tcpSocket := include "definitions.TCPSocketAction" $val | fromYaml }}
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
