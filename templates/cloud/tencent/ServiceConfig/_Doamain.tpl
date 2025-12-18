{{- define "serviceConfig.Domain" -}}
  {{- /* domain string */ -}}
  {{- /* 这个值可以为 "" 所以这里不对其进行判断 */ -}}
  {{- $domain := include "base.getValue" (list . "domain") }}
  {{- include "base.field" (list "domain" $domain "base.string.empty") }}

  {{- /* http2 bool */ -}}
  {{- $http2 := include "base.getValue" (list . "http2") }}
  {{- if $http2 }}
    {{- include "base.field" (list "http2" $http2 "base.bool") }}
  {{- end }}

  {{- /* rules array */ -}}
  {{- $rulesVal := include "base.getValue" (list . "rules") | fromYamlArray }}
  {{- $rules := list }}
  {{- range $rulesVal }}
    {{- $rules = append $rules (include "serviceConfig.DomainRule" . | fromYaml) }}
  {{- end }}
  {{- $rules = $rules | mustUniq | mustCompact }}
  {{- if $rules }}
    {{- include "base.field" (list "rules" $rules "base.slice") }}
  {{- end }}
{{- end }}
