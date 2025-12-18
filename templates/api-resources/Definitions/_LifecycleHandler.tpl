{{- define "definitions.LifecycleHandler" -}}
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

  {{- /* httpGet map */ -}}
  {{- $httpGetVal := include "base.getValue" (list . "httpGet") }}
  {{- if $httpGetVal }}
    {{- $match := regexFindAll $const.k8s.container.httpGet $httpGetVal -1 }}
    {{- if not $match }}
      {{- fail (printf "definitions.LifecycleHandler: HTTPGetAction invalid, Values: '%s', format: '[sheme] [host] [port] path <header|headers> (name value, ...)'" $httpGetVal) }}
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

  {{- /* sleep map */ -}}
  {{- $sleepVal := include "base.getValue" (list . "sleep") }}
  {{- if $sleepVal }}
    {{- $val := dict "seconds" $sleepVal }}
    {{- $sleep := include "definitions.SleepAction" $val | fromYaml }}
    {{- if $sleep }}
      {{- include "base.field" (list "sleep" $sleep "base.map") }}
    {{- end }}
  {{- end }}

  {{- /* tcpSocket map */ -}}
  {{- $tcpSocketVal := include "base.getValue" (list . "tcpSocket") }}
  {{- if $tcpSocketVal }}
    {{- $match := regexFindAll $const.k8s.container.tcpSocket $tcpSocketVal -1 }}
    {{- if not $match }}
      {{- fail (printf "definitions.LifecycleHandler: tcpSocket invalid. Values: %s, format: '[host] port'" .) }}
    {{- end }}

    {{- $host := regexReplaceAll $const.k8s.container.tcpSocket $tcpSocketVal "${1}" | trim }}
    {{- $port := regexReplaceAll $const.k8s.container.tcpSocket $tcpSocketVal "${2}" | trim }}
    {{- $val := dict "host" $host "port" $port }}

    {{- $tcpSocket := include "definitions.TCPSocketAction" $val | fromYaml }}
    {{- if $tcpSocket }}
      {{- include "base.field" (list "tcpSocket" $tcpSocket "base.map") }}
    {{- end }}
  {{- end }}
{{- end }}
