{{- /*
  独立定义格式:
    - 192.168.0.1 1.example.com 1-1.example.com
    - 192.168.0.2 2.example.com
*/ -}}
{{- define "definitions.HostAlias" -}}
  {{- $regexVerify := "^((2(5[0-5]|[0-4]\\d))|[0-1]?\\d{1,2})(\\.((2(5[0-5]|[0-4]\\d))|[0-1]?\\d{1,2})){3}(\\s+[a-zA-Z0-9][-a-zA-Z0-9]{0,62}(\\.[a-zA-Z0-9][-a-zA-Z0-9]{0,62})+)+$" }}
  {{- $const := include "base.env" . | fromYaml }}

  {{- if not (regexMatch $regexVerify .) }}
    {{- fail (printf "definitions.HostAlias: hostAlias(%s) invalid. regex: %s" . $regexVerify) }}
  {{- end }}

  {{- $val := regexSplit $const.regexSplit . -1 }}

  {{- /* hostnames */ -}}
  {{- include "base.field" (list "hostnames" (rest $val) "base.slice") }}

  {{- /* ip */ -}}
  {{- include "base.field" (list "ip" (index $val 0)) }}

{{- end }}
