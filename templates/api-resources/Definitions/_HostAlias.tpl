{{- /*
  独立定义格式:
    - 192.168.0.1 1.example.com 1-1.example.com
    - 192.168.0.2 2.example.com
*/ -}}
{{- define "definitions.HostAlias" -}}
  {{- $const := include "base.env" "" | fromYaml }}

  {{- if not (regexMatch $const.regexHostAlias .) }}
    {{- fail (printf "definitions.HostAlias: hostAlias(%s) invalid. regex: %s" . $const.regexHostAlias) }}
  {{- end }}

  {{- $val := regexSplit $const.regexSplit . -1 }}

  {{- /* hostnames */ -}}
  {{- include "base.field" (list "hostnames" (rest $val) "base.slice") }}

  {{- /* ip */ -}}
  {{- include "base.field" (list "ip" (index $val 0)) }}

{{- end }}
