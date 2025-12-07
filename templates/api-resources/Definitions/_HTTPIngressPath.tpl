{{- define "definitions.HTTPIngressPath" -}}
  {{- /* backend map */ -}}
  {{- $regex1 := "^resource(?:\\s+(\\S+))(?:\\s+(\\S+))(?:\\s+(\\S+))?$" }}
  {{- $regex2 := "^service(?:\\s+(\\S+))(?:\\s+([\\w-]+|0|[1-9]\\d{0,3}|[1-5]\\d{4}|6[0-4]\\d{3}|65[0-4]\\d{2}|655[0-2]\\d|6553[0-5]))$" }}
  {{- $backendVal := include "base.getValue" (list . "backend") }}
  {{- if $backendVal }}
    {{- $backend := dict }}
    {{- $_backend := dict }}

    {{- $match1 := regexFindAll $regex1 $backendVal -1 }}
    {{- $match2 := regexFindAll $regex2 $backendVal -1 }}
    {{- if $match1 }}
      {{- $_ := set $_backend "resource" $backendVal }}
    {{- else if $match2 }}
      {{- $_ := set $_backend "service" $backendVal }}
    {{- else }}
      {{- fail (printf "HTTPIngressPath: backend error. Values: %s, format: 'resource name kind [apiGroup]' or 'service name port.name|port.number'" .) }}
    {{- end }}
    {{- $backend = include "definitions.IngressBackend" $_backend | fromYaml }}
    {{- if $backend }}
      {{- include "base.field" (list "backend" $backend "base.map") }}
    {{- end }}
  {{- end }}

  {{- /* path string */ -}}
  {{- $path := include "base.getValue" (list . "path") }}
  {{- if $path }}
    {{- include "base.field" (list "path" $path) }}
  {{- end }}

  {{- /* pathType string */ -}}
  {{- $pathType := include "base.getValue" (list . "pathType") }}
  {{- $pathTypeAllows := list "Exact" "Prefix" "ImplementationSpecific" }}
  {{- if $pathType }}
    {{- include "base.field" (list "pathType" $pathType "base.string" $pathTypeAllows) }}
  {{- end }}
{{- end }}
