{{- define "definitions.HTTPGetAction" -}}
  {{- $const := include "base.env" "" | fromYaml }}

  {{- /* host string */ -}}
  {{- $host := include "base.getValue" (list . "host") }}
  {{- if $host }}
    {{- include "base.field" (list "host" $host "base.dns") }}
  {{- end }}

  {{- /* httpHeaders array */ -}}
  {{- $httpHeadersVal := include "base.getValue" (list . "httpHeaders") }}
  {{- $httpHeaders := list }}
  {{- if $httpHeadersVal }}
    {{- range (regexSplit $const.split.comma $httpHeadersVal -1) }}
      {{- $_val := regexSplit $const.split.space (. | trim) -1 }}
      {{- if ne (len $_val) 2 }}
        {{- fail (printf "definitions.HTTPGetAction: httpHeaders invalid. Values: '%s', format: 'name value'" .) }}
      {{- end }}
      {{- $val := dict "name" (first $_val) "vlaue" (index $_val 1) }}
      {{- $httpHeaders = append $httpHeaders (include "definitions.HTTPHeader" $val | fromYaml) }}
    {{- end }}
    {{- $httpHeaders = $httpHeaders | mustUniq | mustCompact }}
    {{- if $httpHeaders }}
      {{- include "base.field" (list "httpHeaders" $httpHeaders "base.slice") }}
    {{- end }}
  {{- end }}

  {{- /* path string */ -}}
  {{- $path := include "base.getValue" (list . "path") }}
  {{- if $path }}
    {{- include "base.field" (list "path" (list $path true) "base.uriPath") }}
  {{- end }}

  {{- /* port string */ -}}
  {{- $port := include "base.getValue" (list . "port") }}
  {{- if $port }}
    {{- include "base.field" (list "port" $port "base.port") }}
  {{- end }}

  {{- /* scheme string */ -}}
  {{- $scheme := include "base.getValue" (list . "scheme") }}
  {{- $schemeAllows := list "HTTP" "HTTPS" }}
  {{- if $scheme }}
    {{- include "base.field" (list "scheme" $scheme "base.string" $schemeAllows) }}
  {{- end }}
{{- end }}
