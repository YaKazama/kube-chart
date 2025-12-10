{{- define "definitions.HostPathVolumeSource" -}}
  {{- /* path string */ -}}
  {{- $path := include "base.getValue" (list . "path") }}
  {{- if $path }}
    {{- include "base.field" (list "path" $path "base.absPath") }}
  {{- end }}

  {{- /* type string */ -}}
  {{- $type := include "base.getValue" (list . "type") }}
  {{- $typeAllows := list "DirectoryOrCreate" "Directory" "FileOrCreate" "File" "Socket" "CharDevice" "BlockDevice" }}
  {{- if $type }}
    {{- include "base.field" (list "type" $type "base.string" $typeAllows) }}
  {{- end }}
{{- end }}
