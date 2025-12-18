{{- define "definitions.HTTPIngressPath" -}}
  {{- $const := include "base.env" "" | fromYaml }}

  {{- /* backend map */ -}}
  {{- $backendVal := include "base.getValue" (list . "backend") }}
  {{- if $backendVal }}
    {{- $val := dict }}

    {{- $match1 := regexFindAll $const.k8s.ingress.resource $backendVal -1 }}
    {{- $match2 := regexFindAll $const.k8s.ingress.service $backendVal -1 }}
    {{- if $match1 }}
      {{- $val = dict "resource" $backendVal }}
    {{- else if $match2 }}
      {{- $val = dict "service" $backendVal }}
    {{- else }}
      {{- fail (printf "definitions.HTTPIngressPath: backend invalid. Values: '%s', format: 'resource name kind [apiGroup]' or 'service name port.name|port.number'" .) }}
    {{- end }}
    {{- $backend := include "definitions.IngressBackend" $val | fromYaml }}
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
