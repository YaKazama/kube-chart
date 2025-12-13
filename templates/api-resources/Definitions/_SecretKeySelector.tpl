{{- define "definitions.SecretKeySelector" -}}
  {{- $const := include "base.env" "" | fromYaml }}

  {{- $match := regexFindAll $const.regexSecretKeySelector . -1 }}
  {{- if not $match }}
    {{- fail (printf "SecretKeySelector: error, Values: %s, format: 'name key [optional]'" .) }}
  {{- end }}

  {{- /* key string */ -}}
  {{- $key := regexReplaceAll $const.regexSecretKeySelector . "${2}" }}
  {{- include "base.field" (list "key" $key) }}

  {{- /* name string */ -}}
  {{- $name := regexReplaceAll $const.regexSecretKeySelector . "${1}" }}
  {{- include "base.field" (list "name" $name) }}

  {{- /* optional bool */ -}}
  {{- $optional := regexReplaceAll $const.regexSecretKeySelector . "${3}" }}
  {{- if $optional }}
    {{- include "base.field" (list "optional" $optional "base.bool") }}
  {{- end }}
{{- end }}
