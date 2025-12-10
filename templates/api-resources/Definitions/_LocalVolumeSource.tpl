{{- define "definitions.LocalVolumeSource" -}}
  {{- /* path string */ -}}
  {{- $path := include "base.getValue" (list . "path") }}
  {{- if $path }}
    {{- include "base.field" (list "path" $path "base.absPath") }}
  {{- end }}

  {{- /* fsType string */ -}}
  {{- $fsType := include "base.getValue" (list . "fsType") }}
  {{- $fsTypeAllows := list "ext4" "xfs" "ntfs" }}
  {{- if $fsType }}
    {{- include "base.field" (list "fsType" $fsType "base.string" $fsTypeAllows) }}
  {{- end }}
{{- end }}
