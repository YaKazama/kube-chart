{{- define "definitions.TypedLocalObjectReference" -}}
  {{- /* apiGroup string */ -}}
  {{- $apiGroup := include "base.getValue" (list . "apiGroup") }}
  {{- $_kind := include "base.getValue" (list . "kind") }}
  {{- if and (empty $apiGroup) (ne $_kind "core") }}
    {{- fail (printf "TypedLocalObjectReference: apiGroup '%s' is required when kind is not core." $apiGroup) }}
  {{- end }}
  {{- if $apiGroup }}
    {{- include "base.field" (list "apiGroup" $apiGroup) }}
  {{- end }}

  {{- /* kind string */ -}}
  {{- $kind := include "base.getValue" (list . "kind") }}
  {{- if $kind }}
    {{- include "base.field" (list "kind" $kind) }}
  {{- end }}

  {{- /* name string */ -}}
  {{- $name := include "base.getValue" (list . "name") }}
  {{- if $name }}
    {{- include "base.field" (list "name" $name) }}
  {{- end }}
{{- end }}
