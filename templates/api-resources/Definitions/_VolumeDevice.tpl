{{- define "definitions.VolumeDevice" -}}
  {{- $regex := "^(\\S+)\\s+(\\S+)$" }}

  {{- $match := regexFindAll $regex . -1 }}
  {{- if not $match }}
    {{- fail (printf "volumeDevice: error. Values: %s, format: 'name devicePath'" .) }}
  {{- end }}

  {{- /* devicePath string */ -}}
  {{- $devicePath := regexReplaceAll $regex . "${2}" }}
  {{- include "base.field" (list "devicePath" $devicePath) }}

  {{- /* name string */ -}}
  {{- $name := regexReplaceAll $regex . "${1}" }}
  {{- include "base.field" (list "name" $name) }}
{{- end }}
