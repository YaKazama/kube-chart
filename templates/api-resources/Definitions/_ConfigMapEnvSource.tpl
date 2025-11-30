{{- define "definitions.ConfigMapEnvSource" -}}
  {{- $regex := "^configMap\\s+(\\S+)(?:\\s+(\\S+))?(?:\\s+(true|false))?$" }}

  {{- $match := regexFindAll $regex . -1 }}
  {{- if not $match }}
    {{- fail (printf "ConfigMapEnvSource: error, Values: %s, format: 'sourceName [prefix] [optional]'" .) }}
  {{- end }}

  {{- /* name string */ -}}
  {{- $name := regexReplaceAll $regex . "${1}" }}
  {{- include "base.field" (list "name" $name) }}

  {{- /* optional bool */ -}}
  {{- $optional := regexReplaceAll $regex . "${3}" }}
  {{- if $optional }}
    {{- include "base.field" (list "optional" $optional "base.bool") }}
  {{- end }}
{{- end }}
