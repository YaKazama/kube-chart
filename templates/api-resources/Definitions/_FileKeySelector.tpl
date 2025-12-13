{{- define "definitions.FileKeySelector" -}}
  {{- $const := include "base.env" "" | fromYaml }}

  {{- $match := regexFindAll $const.regexFileKeySelector . -1 }}
  {{- if not $match }}
    {{- fail (printf "FileKeySelector: error, Values: %s, format: 'volumeName path key [optional]'" .) }}
  {{- end }}

  {{- /* key string */ -}}
  {{- $key := regexReplaceAll $const.regexFileKeySelector . "${3}" }}
  {{- include "base.field" (list "key" $key) }}

  {{- /* optional bool */ -}}
  {{- $optional := regexReplaceAll $const.regexFileKeySelector . "${4}" }}
  {{- if $optional }}
    {{- include "base.field" (list "optional" $optional "base.bool") }}
  {{- end }}

  {{- /* path string */ -}}
  {{- $path := regexReplaceAll $const.regexFileKeySelector . "${2}" }}
  {{- include "base.field" (list "path" $path "base.relPath") }}

  {{- /* volumeName string */ -}}
  {{- $volumeName := regexReplaceAll $const.regexFileKeySelector . "${1}" }}
  {{- include "base.field" (list "volumeName" $volumeName) }}
{{- end }}
