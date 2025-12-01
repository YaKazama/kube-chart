{{- define "definitions.LocalVolumeSource" -}}
  {{- $regex := "^(\\S+)$" }}

  {{- $match := regexFindAll $regex . -1 }}
  {{- if not $match }}
    {{- fail (printf "local: error. Values: %s, format: 'path'" .) }}
  {{- end }}

  {{- /* path string */ -}}
  {{- $path := regexReplaceAll $regex . "${1}" | trim }}
  {{- include "base.field" (list "path" $path) }}
{{- end }}
