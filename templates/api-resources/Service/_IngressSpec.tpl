{{- define "service.IngressSpec" -}}
  {{- $const := include "base.env" "" | fromYaml }}

  {{- /* defaultBackend map */ -}}
  {{- $_rules := include "base.getValue" (list . "rules") | fromYamlArray }}
  {{- if not $_rules }}
    {{- $defaultBackendVal := include "base.getValue" (list . "defaultBackend") }}
    {{- $defaultBackend := dict }}
    {{- $_defaultBackend := dict }}

    {{- $match1 := regexFindAll $const.regexIngressSpecResource $defaultBackendVal -1 }}
    {{- $match2 := regexFindAll $const.regexIngressSpecService $defaultBackendVal -1 }}
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
  {{- range $tlsVal }}
    {{- $val := dict }}

    {{- $match := regexFindAll $const.regexIngressSpecTLS . -1 }}
    {{- if not $match }}
      {{- fail (printf "IngressSpec: tls error. secretName and hosts must be exists. Values: %s, format: 'secretName hosts hostsN'" .) }}
    {{- end }}

    {{- $_val := regexSplit $const.regexSplit . -1 }}
    {{- $_ := set $val "secretName" (first $_val) }}
    {{- $_ := set $val "hosts" (include "base.slice" (slice $_val 1) | fromYamlArray) }}

    {{- $tls = append $tls (include "definitions.IngressTLS" $val | fromYaml) }}
  {{- end }}
  {{- $tls = $tls | mustUniq | mustCompact }}
  {{- if $tls }}
    {{- include "base.field" (list "tls" $tls "base.slice") }}
  {{- end }}
{{- end }}
