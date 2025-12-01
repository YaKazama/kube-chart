{{- define "definitions.TypedLocalObjectReference" -}}
  {{- /* apiGroup string */ -}}
  {{- $apiGroup := include "base.getValue" (list . "apiGroup") }}
  {{- if $apiGroup }}
    {{- include "basef.field" (list "apiGroup" $apiGroup) }}
  {{- end }}

  {{- /* kind string */ -}}
  {{- $kind := include "base.getValue" (list . "kind") }}
  {{- if $kind }}
    {{- include "basef.field" (list "kind" $kind) }}
  {{- end }}

  {{- /* name string */ -}}
  {{- $name := include "base.getValue" (list . "name") }}
  {{- if $name }}
    {{- include "basef.field" (list "name" $name) }}
  {{- end }}
{{- end }}
