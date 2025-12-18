{{- define "definitions.FileKeySelector" -}}
  {{- /* key string */ -}}
  {{- $key := include "base.getValue" (list . "key") }}
  {{- if $key }}
    {{- include "base.field" (list "key" $key) }}
  {{- end }}

  {{- /* optional bool */ -}}
  {{- $optional := include "base.getValue" (list . "optional") }}
  {{- if $optional }}
    {{- include "base.field" (list "optional" $optional "base.bool") }}
  {{- end }}

  {{- /* path string */ -}}
  {{- $path := include "base.getValue" (list . "path") }}
  {{- if $path }}
    {{- include "base.field" (list "path" $path "base.relPath") }}
  {{- end }}

  {{- /* volumeName string */ -}}
  {{- $volumeName := include "base.getValue" (list . "volumeName") }}
  {{- if $volumeName }}
    {{- include "base.field" (list "volumeName" $volumeName) }}
  {{- end }}
{{- end }}
