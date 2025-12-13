{{- define "definitions.HTTPIngressRuleValue" -}}
  {{- $const := include "base.env" "" | fromYaml }}

  {{- /* paths array */ -}}
  {{- $pathsVal := include "base.getValue" (list . "paths") | fromYamlArray }}
  {{- $paths := list }}
  {{- range $pathsVal }}
    {{- $val := dict }}

    {{- $match := regexFindAll $const.regexHTTPIngressRuleValue . -1 }}
    {{- if $match }}
      {{- $_ := set $val "path" (regexReplaceAll $const.regexHTTPIngressRuleValue . "${1}") }}
      {{- $_ := set $val "pathType" (regexReplaceAll $const.regexHTTPIngressRuleValue . "${2}") }}
      {{- $_ := set $val "backend" (regexReplaceAll $const.regexHTTPIngressRuleValue . "${3} ${4}") }}
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
