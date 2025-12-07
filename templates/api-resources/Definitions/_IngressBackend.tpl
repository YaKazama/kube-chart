{{- define "definitions.IngressBackend" -}}
  {{- /* resource map */ -}}
  {{- $resourceVal := include "base.getValue" (list . "resource") }}
  {{- if $resourceVal }}
    {{- $regex := "^resource(?:\\s+(\\S+))(?:\\s+(\\S+))(?:\\s+(\\S+))?$" }}
    {{- $match := regexFindAll $regex $resourceVal -1 }}
    {{- if not $match }}
      {{- fail (printf "IngressBackend: resource error. Values: %s, format: 'resource name kind [apiGroup]'" .) }}
    {{- end }}

    {{- $_resource := dict }}
    {{- $_ := set $_resource "name" (regexReplaceAll $regex $resourceVal "${1}") }}
    {{- $_ := set $_resource "kind" (regexReplaceAll $regex $resourceVal "${2}") }}
    {{- $_ := set $_resource "apiGroup" (regexReplaceAll $regex $resourceVal "${3}") }}

    {{- $resource := include "definitions.TypedLocalObjectReference" $_resource | fromYaml }}
    {{- if $resource }}
      {{- include "base.field" (list "resource" $resource "base.map") }}
    {{- end }}
  {{- end }}

  {{- /* service map */ -}}
  {{- $serviceVal := include "base.getValue" (list . "service") }}
  {{- if $serviceVal }}
    {{- $regex := "^service(?:\\s+(\\S+))(?:\\s+([\\w-]+|0|[1-9]\\d{0,3}|[1-5]\\d{4}|6[0-4]\\d{3}|65[0-4]\\d{2}|655[0-2]\\d|6553[0-5]))$" }}
    {{- $match := regexFindAll $regex $serviceVal -1 }}
    {{- if not $match }}
      {{- fail (printf "IngressBackend: service error. Values: %s, format: 'service name port.name|port.number'" .) }}
    {{- end }}

    {{- $_service := dict }}
    {{- $_ := set $_service "name" (regexReplaceAll $regex $serviceVal "${1}") }}
    {{- $_ := set $_service "port" (regexReplaceAll $regex $serviceVal "${2}") }} {{- /* 这里传递的是一个字符串 */ -}}

    {{- $service := include "definitions.IngressServiceBackend" $_service | fromYaml }}
    {{- if $service }}
      {{- include "base.field" (list "service" $service "base.map") }}
    {{- end }}
  {{- end }}
{{- end }}
