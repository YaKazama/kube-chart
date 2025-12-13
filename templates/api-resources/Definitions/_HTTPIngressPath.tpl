{{- define "definitions.HTTPIngressPath" -}}
  {{- $const := include "base.env" "" | fromYaml }}

  {{- /* backend map */ -}}
  {{- $backendVal := include "base.getValue" (list . "backend") }}
  {{- if $backendVal }}
    {{- $backend := dict }}
    {{- $_backend := dict }}

    {{- $match1 := regexFindAll $const.regexHTTPIngressPathResource $backendVal -1 }}
    {{- $match2 := regexFindAll $const.regexHTTPIngressPathService $backendVal -1 }}
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
    {{- include "base.field" (list "path" $path "base.absPath") }}
  {{- end }}

  {{- /* pathType string */ -}}
  {{- $pathType := include "base.getValue" (list . "pathType") }}
  {{- $pathTypeAllows := list "Exact" "Prefix" "ImplementationSpecific" }}
  {{- if $pathType }}
    {{- include "base.field" (list "pathType" $pathType "base.string" $pathTypeAllows) }}
  {{- end }}
{{- end }}
