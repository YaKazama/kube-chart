{{- define "definitions.FileKeySelector" -}}
  {{- $regex := "^file\\s+(\\S+)\\s+(\\S+)\\s+(\\S+)(?:\\s+(true|false))?$" }}

  {{- $match := regexFindAll $regex . -1 }}
  {{- if not $match }}
    {{- fail (printf "FileKeySelector: error, Values: %s, format: 'volumeName path key [optional]'" .) }}
  {{- end }}

  {{- /* key string */ -}}
  {{- $key := regexReplaceAll $regex . "${3}" }}
  {{- include "base.field" (list "key" $key) }}

  {{- /* optional bool */ -}}
  {{- $optional := regexReplaceAll $regex . "${4}" }}
  {{- if $optional }}
    {{- include "base.field" (list "optional" $optional "base.bool") }}
  {{- end }}

  {{- /* path string */ -}}
  {{- $path := regexReplaceAll $regex . "${2}" }}
  {{- include "base.field" (list "path" $path "base.relPath") }}

  {{- /* volumeName string */ -}}
  {{- $volumeName := regexReplaceAll $regex . "${1}" }}
  {{- include "base.field" (list "volumeName" $volumeName) }}
{{- end }}
