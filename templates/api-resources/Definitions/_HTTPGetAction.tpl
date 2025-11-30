{{- define "definitions.HTTPGetAction" -}}
  {{- $regex := "^(?:(HTTP|http|HTTPS|https)\\s+)?(?:(\\S+)\\s+)?(?:(\\d+)\\s+)?(\\S+)(?:\\s+(header|headers)\\s+\\((.*?)\\))?$" }}

  {{- $match := regexFindAll $regex . -1 }}
  {{- if not $match }}
    {{- fail (printf "HTTPGetAction: error, Values: %s, format: '[sheme] [host] [port] path <header|headers> (name value, ...)'" .) }}
  {{- end }}

  {{- /* host string */ -}}
  {{- $host := regexReplaceAll $regex . "${2}" }}
  {{- if $host }}
    {{- include "base.field" (list "host" $host) }}
  {{- end }}

  {{- /* httpHeaders array */ -}}
  {{- $httpHeadersKeywords := regexReplaceAll $regex . "${5}" }}
  {{- if or (eq $httpHeadersKeywords "header") (eq $httpHeadersKeywords "headers") }}
    {{- $httpHeadersVal := regexReplaceAll $regex . "${6}" }}
    {{- $httpHeaders := list }}
    {{- $_headers := regexSplit ",\\s*" $httpHeadersVal -1 }}
    {{- range $_headers }}
      {{- $val := dict }}
      {{- $_val := regexSplit " " (. | trim) -1 }}
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
  {{- $path := regexReplaceAll $regex . "${4}" }}
  {{- if empty $path }}
    {{- fail "HTTPGetAction: path must be exists." }}
  {{- end }}
  {{- include "base.field" (list "path" $path) }}

  {{- /* port string */ -}}
  {{- $port := regexReplaceAll $regex . "${3}" }}
  {{- if $port }}
    {{- include "base.field" (list "port" $port "base.port") }}
  {{- end }}

  {{- /* scheme string */ -}}
  {{- $scheme := regexReplaceAll $regex . "${1}" | upper }}
  {{- if $scheme }}
    {{- include "base.field" (list "scheme" $scheme) }}
  {{- end }}
{{- end }}
