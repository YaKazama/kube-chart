{{- define "definitions.HTTPIngressRuleValue" -}}
  {{- $const := include "base.env" "" | fromYaml }}

  {{- /* paths array */ -}}
  {{- $pathsVal := include "base.getValue" (list . "paths") | fromYamlArray }}
  {{- $paths := list }}
  {{- range $pathsVal }}
    {{- $val := dict }}

    {{- $match := regexFindAll $const.k8s.ingress.path . -1 }}
    {{- if $match }}
      {{- $path := regexReplaceAll $const.k8s.ingress.path . "${1}" | trim }}
      {{- $pathType := regexReplaceAll $const.k8s.ingress.path . "${2}" | trim }}
      {{- $backend := regexReplaceAll $const.k8s.ingress.path . "${3} ${4}" | trim }}
      {{- $val = dict "path" $path "pathType" $pathType "backend" $backend }}

    {{- else }}
      {{- fail (printf "HTTPIngressRuleValue: paths error. Values: %s, format: 'path [pathType] resource name kind [apiGroup]' or 'path [pathType] service name port.name|port.number'" .) }}
    {{- end }}

    {{- $paths = append $paths (include "definitions.HTTPIngressPath" $val | fromYaml) }}
  {{- end }}
  {{- $paths = $paths | mustUniq | mustCompact }}
  {{- if $paths }}
    {{- include "base.field" (list "paths" $paths "base.slice") }}
  {{- end }}
{{- end }}
