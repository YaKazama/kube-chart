{{- define "definitions.SecretEnvSource" -}}
  {{- $const := include "base.env" "" | fromYaml }}

  {{- $match := regexFindAll $const.regexSecretEnvSource . -1 }}
  {{- if not $match }}
    {{- fail (printf "SecretEnvSource: error, Values: %s, format: 'sourceName [prefix] [optional]'" .) }}
  {{- end }}

  {{- /* name string */ -}}
  {{- $name := regexReplaceAll $const.regexSecretEnvSource . "${1}" }}
  {{- include "base.field" (list "name" $name) }}

  {{- /* optional bool */ -}}
  {{- $optional := regexReplaceAll $const.regexSecretEnvSource . "${3}" }}
  {{- if $optional }}
    {{- include "base.field" (list "optional" $optional "base.bool") }}
  {{- end }}
{{- end }}
