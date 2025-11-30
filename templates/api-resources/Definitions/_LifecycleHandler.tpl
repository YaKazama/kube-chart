{{- define "definitions.LifecycleHandler" -}}
  {{- /* exec map */ -}}
  {{- $execVal := include "base.getValue" (list . "exec") | fromYamlArray }}
  {{- if $execVal }}
    {{- $exec := include "definitions.ExecAction" $execVal | fromYaml }}
    {{- if $exec }}
      {{- include "base.field" (list "exec" $exec "base.map") }}
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

  {{- /* sleep map */ -}}
  {{- $sleepVal := include "base.getValue" (list . "sleep") }}
  {{- if $sleepVal }}
    {{- $sleep := include "definitions.SleepAction" $sleepVal | fromYaml }}
    {{- if $sleep }}
      {{- include "base.field" (list "sleep" $sleep "base.map") }}
    {{- end }}
  {{- end }}

  {{- /* tcpSocket map */ -}}
  {{- $tcpSocketVal := include "base.getValue" (list . "tcpSocket") }}
  {{- if $tcpSocketVal }}
    {{- $tcpSocket := include "definitions.TCPSocketAction" $tcpSocketVal | fromYaml }}
    {{- if $tcpSocket }}
      {{- include "base.field" (list "tcpSocket" $tcpSocket "base.map") }}
    {{- end }}
  {{- end }}
{{- end }}
