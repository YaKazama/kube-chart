{{- define "service.IngressSpec" -}}
  {{- $const := include "base.env" "" | fromYaml }}

  {{- /* defaultBackend map */ -}}
  {{- $_rules := include "base.getValue" (list . "rules") | fromYamlArray }}
  {{- if not $_rules }}
    {{- $defaultBackendVal := include "base.getValue" (list . "defaultBackend") }}
    {{- $val := dict }}

    {{- $match1 := regexFindAll $const.k8s.ingress.resource $defaultBackendVal -1 }}
    {{- $match2 := regexFindAll $const.k8s.ingress.service $defaultBackendVal -1 }}
    {{- if $match1 }}
      {{- $val = dict "resource" $defaultBackendVal }}
    {{- else if $match2 }}
      {{- $val = dict "service" $defaultBackendVal }}
    {{- else }}
      {{- fail (printf "service.IngressSpec: defaultBackend invalid. Values: %s, format: 'resource name kind [apiGroup]' or 'service name port.name|port.number'" .) }}
    {{- end }}
    {{- $defaultBackend := include "definitions.IngressBackend" $val | fromYaml }}
    {{- if $defaultBackend }}
      {{- include "base.field" (list "defaultBackend" $defaultBackend "base.map") }}
    {{- end }}
  {{- end }}

  {{- /* ingressClassName string */ -}}
  {{- $ingressClassName := include "base.getValue" (list . "ingressClassName") }}
  {{- if $ingressClassName }}
    {{- include "base.field" (list "ingressClassName" $ingressClassName) }}
  {{- end }}

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
    {{- $match := regexFindAll $const.k8s.ingress.tls . -1 }}
    {{- if not $match }}
      {{- fail (printf "service.IngressSpec: tls invalid. secretName and hosts must be exists. Values: %s, format: 'secretName hosts hostsN'" .) }}
    {{- end }}

    {{- $_val := regexSplit $const.split.space . -1 }}
    {{- $secretName := first $_val | trim }}
    {{- $hosts := include "base.slice" (slice $_val 1) | fromYamlArray }}
    {{- $val := dict "secretName" $secretName "hosts" $hosts }}

    {{- $tls = append $tls (include "definitions.IngressTLS" $val | fromYaml) }}
  {{- end }}
  {{- $tls = $tls | mustUniq | mustCompact }}
  {{- if $tls }}
    {{- include "base.field" (list "tls" $tls "base.slice") }}
  {{- end }}
{{- end }}
