{{- define "definitions.SecretKeySelector" -}}
  {{- $regex := "^secret\\s+(\\S+)\\s+(\\S+)(?:\\s+(true|false))?$" }}

  {{- $match := regexFindAll $regex . -1 }}
  {{- if not $match }}
    {{- fail (printf "SecretKeySelector: error, Values: %s, format: 'name key [optional]'" .) }}
  {{- end }}

  {{- /* key string */ -}}
  {{- $key := regexReplaceAll $regex . "${2}" }}
  {{- include "base.field" (list "key" $key) }}

  {{- /* name string */ -}}
  {{- $name := regexReplaceAll $regex . "${1}" }}
  {{- include "base.field" (list "name" $name) }}

  {{- /* optional bool */ -}}
  {{- $optional := regexReplaceAll $regex . "${3}" }}
  {{- if $optional }}
    {{- include "base.field" (list "optional" $optional "base.bool") }}
  {{- end }}
{{- end }}
