{{- define "definitions.IngressBackend" -}}
  {{- $const := include "base.env" "" | fromYaml }}

  {{- /* resource map */ -}}
  {{- $resourceVal := include "base.getValue" (list . "resource") }}
  {{- if $resourceVal }}
    {{- $match := regexFindAll $const.regexIngressBackendResource $resourceVal -1 }}
    {{- if not $match }}
      {{- fail (printf "IngressBackend: resource error. Values: %s, format: 'resource name kind [apiGroup]'" .) }}
    {{- end }}

    {{- $_resource := dict }}
    {{- $_ := set $_resource "name" (regexReplaceAll $const.regexIngressBackendResource $resourceVal "${1}") }}
    {{- $_ := set $_resource "kind" (regexReplaceAll $const.regexIngressBackendResource $resourceVal "${2}") }}
    {{- $_ := set $_resource "apiGroup" (regexReplaceAll $const.regexIngressBackendResource $resourceVal "${3}") }}

    {{- $resource := include "definitions.TypedLocalObjectReference" $_resource | fromYaml }}
    {{- if $resource }}
      {{- include "base.field" (list "resource" $resource "base.map") }}
    {{- end }}
  {{- end }}

  {{- /* service map */ -}}
  {{- $serviceVal := include "base.getValue" (list . "service") }}
  {{- if $serviceVal }}
    {{- $match := regexFindAll $const.regexIngressBackendService $serviceVal -1 }}
    {{- if not $match }}
      {{- fail (printf "IngressBackend: service error. Values: %s, format: 'service name port.name|port.number'" .) }}
    {{- end }}

    {{- $_service := dict }}
    {{- $_ := set $_service "name" (regexReplaceAll $const.regexIngressBackendService $serviceVal "${1}") }}
    {{- $_ := set $_service "port" (regexReplaceAll $const.regexIngressBackendService $serviceVal "${2}") }} {{- /* 这里传递的是一个字符串 */ -}}

    {{- $service := include "definitions.IngressServiceBackend" $_service | fromYaml }}
    {{- if $service }}
      {{- include "base.field" (list "service" $service "base.map") }}
    {{- end }}
  {{- end }}
{{- end }}
