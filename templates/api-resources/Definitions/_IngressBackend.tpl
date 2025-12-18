{{- define "definitions.IngressBackend" -}}
  {{- $const := include "base.env" "" | fromYaml }}

  {{- /* resource map */ -}}
  {{- $resourceVal := include "base.getValue" (list . "resource") }}
  {{- if $resourceVal }}
    {{- $match := regexFindAll $const.k8s.ingress.resource $resourceVal -1 }}
    {{- if not $match }}
      {{- fail (printf "IngressBackend: resource error. Values: %s, format: 'resource name kind [apiGroup]'" .) }}
    {{- end }}

    {{- $name := regexReplaceAll $const.k8s.ingress.resource $resourceVal "${1}" | trim }}
    {{- $kind := regexReplaceAll $const.k8s.ingress.resource $resourceVal "${2}" | trim }}
    {{- $apiGroup := regexReplaceAll $const.k8s.ingress.resource $resourceVal "${3}" | trim }}
    {{- $val := dict "name" $name "kind" $kind "apiGroup" $apiGroup }}

    {{- $resource := include "definitions.TypedLocalObjectReference" $val | fromYaml }}
    {{- if $resource }}
      {{- include "base.field" (list "resource" $resource "base.map") }}
    {{- end }}
  {{- end }}

  {{- /* service map */ -}}
  {{- $serviceVal := include "base.getValue" (list . "service") }}
  {{- if $serviceVal }}
    {{- $match := regexFindAll $const.k8s.ingress.service $serviceVal -1 }}
    {{- if not $match }}
      {{- fail (printf "IngressBackend: service error. Values: %s, format: 'service name port.name|port.number'" .) }}
    {{- end }}

    {{- $name := regexReplaceAll $const.k8s.ingress.service $serviceVal "${1}" | trim }}
    {{- $port := regexReplaceAll $const.k8s.ingress.service $serviceVal "${2}" | trim }} {{- /* 这里传递的是一个字符串 */ -}}
    {{- $val := dict "name" $name "port" $port }}

    {{- $service := include "definitions.IngressServiceBackend" $val | fromYaml }}
    {{- if $service }}
      {{- include "base.field" (list "service" $service "base.map") }}
    {{- end }}
  {{- end }}
{{- end }}
