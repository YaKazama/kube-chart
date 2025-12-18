{{- define "kustomization.ReplacementSourceOption" -}}
  {{- /* delimiter string */ -}}
  {{- $delimiter := include "base.getValue" (list . "delimiter") }}
  {{- if $delimiter }}
    {{- include "base.field" (list "delimiter" $delimiter) }}
  {{- end }}

  {{- /* index int */ -}}
  {{- $index := include "base.getValue" (list . "index" "toString") }}
  {{- if $index }}
    {{- include "base.field" (list "index" $index "base.int") }}
  {{- end }}

  {{- /* create bool */ -}}
  {{- $create := include "base.getValue" (list . "create") }}
  {{- if $create }}
    {{- include "base.field" (list "create" $create "base.bool") }}
  {{- end }}
{{- end }}
