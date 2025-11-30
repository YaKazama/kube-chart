{{- define "definitions.NFSVolumeSource" -}}
  {{- $regex := "^(\\S+)\\s+(\\S+)\\s*(true|false)?$" }}

  {{- $match := regexFindAll $regex . -1 }}
  {{- if not $match }}
    {{- fail (printf "nfs: error. Values: %s, format: 'server path [readOnly]'" .) }}
  {{- end }}

  {{- /* path string */ -}}
  {{- $path := regexReplaceAll $regex . "${2}" | trim }}
  {{- include "base.field" (list "path" $path) }}

  {{- /* readOnly bool */ -}}
  {{- $readOnly := regexReplaceAll $regex . "${3}" | trim }}
  {{- if $readOnly }}
    {{- include "base.field" (list "readOnly" $readOnly "base.bool") }}
  {{- end }}

  {{- /* server string */ -}}
  {{- $server := regexReplaceAll $regex . "${1}" | trim }}
  {{- include "base.field" (list "server" $server) }}
{{- end }}
