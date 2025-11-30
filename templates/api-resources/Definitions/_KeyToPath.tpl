{{- define "definitions.KeyToPath" -}}
  {{- /* key string */ -}}
  {{- $key := include "base.getValue" (list . "key") }}
  {{- if $key }}
    {{- include "base.field" (list "key" $key) }}
  {{- end }}

  {{- /* mode int */ -}}
  {{- $mode := include "base.getValue" (list . "mode") }}
  {{- if $mode }}
    {{- include "base.field" (list "mode" $mode "base.fileMode") }}
  {{- end }}

  {{- /* path string */ -}}
  {{- $path := include "base.getValue" (list . "path") }}
  {{- if $path }}
    {{- include "base.field" (list "path" $path) }}
  {{- end }}

{{- end }}
