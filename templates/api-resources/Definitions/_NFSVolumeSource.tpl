{{- define "definitions.NFSVolumeSource" -}}
  {{- /* path string */ -}}
  {{- $path := include "base.getValue" (list . "path") }}
  {{- if $path }}
    {{- include "base.field" (list "path" $path "base.absPath") }}
  {{- end }}

  {{- /* readOnly bool */ -}}
  {{- $readOnly := include "base.getValue" (list . "readOnly") }}
  {{- if $readOnly }}
    {{- include "base.field" (list "readOnly" $readOnly "base.bool") }}
  {{- end }}

  {{- /* server string */ -}}
  {{- $server := include "base.getValue" (list . "server") }}
  {{- if $server }}
    {{- include "base.field" (list "server" $server) }}
  {{- end }}
{{- end }}
