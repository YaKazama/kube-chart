{{- define "definitions.VolumeDevice" -}}
  {{- $const := include "base.env" "" | fromYaml }}

  {{- $match := regexFindAll $const.regexVolumeDevice . -1 }}
  {{- if not $match }}
    {{- fail (printf "volumeDevice: error. Values: %s, format: 'name devicePath'" .) }}
  {{- end }}

  {{- /* devicePath string */ -}}
  {{- $devicePath := regexReplaceAll $const.regexVolumeDevice . "${2}" }}
  {{- include "base.field" (list "devicePath" $devicePath "base.absPath") }}

  {{- /* name string */ -}}
  {{- $name := regexReplaceAll $const.regexVolumeDevice . "${1}" }}
  {{- include "base.field" (list "name" $name) }}
{{- end }}
