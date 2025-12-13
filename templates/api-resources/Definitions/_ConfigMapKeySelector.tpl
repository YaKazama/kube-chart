{{- define "definitions.ConfigMapKeySelector" -}}
  {{- $const := include "base.env" "" | fromYaml }}

  {{- $match := regexFindAll $const.regexConfigMap . -1 }}
  {{- if not $match }}
    {{- fail (printf "definitions.ConfigMapKeySelector: error, Values: %s, format: 'name key [optional]'" .) }}
  {{- end }}

  {{- /* key string */ -}}
  {{- $key := regexReplaceAll $const.regexConfigMap . "${2}" }}
  {{- include "base.field" (list "key" $key) }}

  {{- /* name string */ -}}
  {{- $name := regexReplaceAll $const.regexConfigMap . "${1}" }}
  {{- include "base.field" (list "name" $name) }}

  {{- /* optional bool */ -}}
  {{- $optional := regexReplaceAll $const.regexConfigMap . "${3}" }}
  {{- if $optional }}
    {{- include "base.field" (list "optional" $optional "base.bool") }}
  {{- end }}
{{- end }}
