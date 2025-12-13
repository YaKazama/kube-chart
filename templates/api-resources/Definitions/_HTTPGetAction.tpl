{{- define "definitions.HTTPGetAction" -}}
  {{- $const := include "base.env" "" | fromYaml }}

  {{- $match := regexFindAll $const.regexHTTPGetAction . -1 }}
  {{- if not $match }}
    {{- fail (printf "HTTPGetAction: error, Values: %s, format: '[sheme] [host] [port] path <header|headers> (name value, ...)'" .) }}
  {{- end }}

  {{- /* host string */ -}}
  {{- $host := regexReplaceAll $const.regexHTTPGetAction . "${2}" }}
  {{- if $host }}
    {{- include "base.field" (list "host" $host) }}
  {{- end }}

  {{- /* httpHeaders array */ -}}
  {{- $httpHeadersKeywords := regexReplaceAll $const.regexHTTPGetAction . "${5}" }}
  {{- if or (eq $httpHeadersKeywords "header") (eq $httpHeadersKeywords "headers") }}
    {{- $httpHeadersVal := regexReplaceAll $const.regexHTTPGetAction . "${6}" }}
    {{- $httpHeaders := list }}
    {{- $_headers := regexSplit $const.regexSplitComma $httpHeadersVal -1 }}
    {{- range $_headers }}
      {{- $val := dict }}
      {{- $_val := regexSplit $const.regexSplit (. | trim) -1 }}
      {{- if ne (len $_val) 2 }}
        {{- fail (printf "HTTPGetAction: headers invalid. Values: '%s', format: 'name value'" .) }}
      {{- end }}
      {{- $_ := set $val "name" (index $_val 0) }}
      {{- $_ := set $val "value" (index $_val 1) }}
      {{- $httpHeaders = append $httpHeaders (include "definitions.HTTPHeader" $val | fromYaml) }}
    {{- end }}
    {{- $httpHeaders = $httpHeaders | mustUniq | mustCompact }}
    {{- if $httpHeaders }}
      {{- include "base.field" (list "httpHeaders" $httpHeaders "base.slice") }}
    {{- end }}
  {{- end }}

  {{- /* path string */ -}}
  {{- $path := regexReplaceAll $const.regexHTTPGetAction . "${4}" }}
  {{- if empty $path }}
    {{- fail "HTTPGetAction: path must be exists." }}
  {{- end }}
  {{- include "base.field" (list "path" $path "base.absPath") }}

  {{- /* port string */ -}}
  {{- $port := regexReplaceAll $const.regexHTTPGetAction . "${3}" }}
  {{- if $port }}
    {{- include "base.field" (list "port" $port "base.port") }}
  {{- end }}

  {{- /* scheme string */ -}}
  {{- $scheme := regexReplaceAll $const.regexHTTPGetAction . "${1}" | upper }}
  {{- if $scheme }}
    {{- include "base.field" (list "scheme" $scheme) }}
  {{- end }}
{{- end }}
