{{- define "definitions.VolumeDevice" -}}
  {{- /* devicePath string */ -}}
  {{- $devicePath := include "base.getValue" (list . "devicePath") }}
  {{- if $devicePath }}
    {{- include "base.field" (list "devicePath" $devicePath "base.absPath") }}
  {{- end }}

  {{- /* name string */ -}}
  {{- $name := include "base.getValue" (list . "name") }}
  {{- if $name }}
    {{- include "base.field" (list "name" $name "base.rfc1035") }}
  {{- end }}
{{- end }}
