{{- define "definitions.HostPathVolumeSource" -}}
  {{- $regex := "^(\\S+)\\s*(DirectoryOrCreate|Directory|FileOrCreate|File|Socket|CharDevice|BlockDevice)?$" }}

  {{- $match := regexFindAll $regex . -1 }}
  {{- if not $match }}
    {{- fail (printf "hostPath: error. Values: %s, format: 'path [type]'" .) }}
  {{- end }}

  {{- /* path string */ -}}
  {{- $path := regexReplaceAll $regex . "${1}" }}
  {{- include "base.field" (list "path" $path) }}

  {{- /* type string */ -}}
  {{- $type := regexReplaceAll $regex . "${2}" }}
  {{- if $type }}
    {{- include "base.field" (list "type" $type) }}
  {{- end }}
{{- end }}
