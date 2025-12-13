{{- define "definitions.ConfigMapEnvSource" -}}
  {{- $const := include "base.env" "" | fromYaml }}

  {{- $match := regexFindAll $const.regexConfigMap . -1 }}
  {{- if not $match }}
    {{- fail (printf "definitions.ConfigMapEnvSource: error, Values: %s, format: 'sourceName [prefix] [optional]'" .) }}
  {{- end }}

  {{- /* name string */ -}}
  {{- $name := regexReplaceAll $const.regexConfigMap . "${1}" }}
  {{- include "base.field" (list "name" $name) }}

  {{- /* optional bool */ -}}
  {{- $optional := regexReplaceAll $const.regexConfigMap . "${3}" }}
  {{- if $optional }}
    {{- include "base.field" (list "optional" $optional "base.bool") }}
  {{- end }}
{{- end }}
