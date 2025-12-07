{{- define "service.IngressSpec" -}}
  {{- /* defaultBackend map */ -}}
  {{- $_rules := include "base.getValue" (list . "rules") | fromYamlArray }}
  {{- if not $_rules }}
    {{- $regex1 := "^resource(?:\\s+(\\S+))(?:\\s+(\\S+))(?:\\s+(\\S+))?$" }}
    {{- $regex2 := "^service(?:\\s+(\\S+))(?:\\s+([\\w-]+|0|[1-9]\\d{0,3}|[1-5]\\d{4}|6[0-4]\\d{3}|65[0-4]\\d{2}|655[0-2]\\d|6553[0-5]))$" }}
    {{- $defaultBackendVal := include "base.getValue" (list . "defaultBackend") }}
    {{- $defaultBackend := dict }}
    {{- $_defaultBackend := dict }}

    {{- $match1 := regexFindAll $regex1 $defaultBackendVal -1 }}
    {{- $match2 := regexFindAll $regex2 $defaultBackendVal -1 }}
    {{- if $match1 }}
      {{- $_ := set $_defaultBackend "resource" $defaultBackendVal }}
    {{- else if $match2 }}
      {{- $_ := set $_defaultBackend "service" $defaultBackendVal }}
    {{- else }}
      {{- fail (printf "IngressSpec: defaultBackend error. Values: %s, format: 'resource name kind [apiGroup]' or 'service name port.name|port.number'" .) }}
    {{- end }}
    {{- $defaultBackend = include "definitions.IngressBackend" $_defaultBackend | fromYaml }}
    {{- if $defaultBackend }}
      {{- include "base.field" (list "defaultBackend" $defaultBackend "base.map") }}
    {{- end }}
  {{- end }}

  {{- /* ingressClassName string */ -}}
  {{- $ingressClassName := include "base.getValue" (list . "ingressClassName") }}
  {{- include "base.field" (list "ingressClassName" $ingressClassName) }}

  {{- /* rules array */ -}}
  {{- $rulesVal := include "base.getValue" (list . "rules") | fromYaml }}
  {{- $rules := list }}
  {{- range $host, $http := $rulesVal }}
    {{- $val := dict "host" $host "http" $http }}
    {{- $rules = append $rules (include "definitions.IngressRule" $val | fromYaml) }}
  {{- end }}
  {{- $rules = $rules | mustUniq | mustCompact }}
  {{- if $rules }}
    {{- include "base.field" (list "rules" $rules "base.slice") }}
  {{- end }}

  {{- /* tls array */ -}}
  {{- $tlsVal := include "base.getValue" (list . "tls") | fromYamlArray }}
  {{- $tls := list }}
  {{- $regex := "^([a-z0-9-]+)(?:\\s+((?:\\*\\.)?[a-z0-9-]+(?:\\.[a-z0-9-]+)+))(?:\\s+((?:\\*\\.)?[a-z0-9-]+(?:\\.[a-z0-9-]+)+))*$" }}
  {{- range $tlsVal }}
    {{- $val := dict }}

    {{- $match := regexFindAll $regex . -1 }}
    {{- if not $match }}
      {{- fail (printf "IngressSpec: tls error. secretName and hosts must be exists. Values: %s, format: 'secretName hosts hostsN'" .) }}
    {{- end }}

    {{- $_val := regexSplit "\\s+" . -1 }}
    {{- $_ := set $val "secretName" (first $_val) }}
    {{- $_ := set $val "hosts" (include "base.slice" (slice $_val 1) | fromYamlArray) }}

    {{- $tls = append $tls (include "definitions.IngressTLS" $val | fromYaml) }}
  {{- end }}
  {{- $tls = $tls | mustUniq | mustCompact }}
  {{- if $tls }}
    {{- include "base.field" (list "tls" $tls "base.slice") }}
  {{- end }}
{{- end }}
