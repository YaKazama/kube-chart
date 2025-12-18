{{- define "kustomization.Replicas" -}}
  {{- /* name string */ -}}
  {{- $name := include "base.getValue" (list . "name") }}
  {{- if $name }}
    {{- include "base.field" (list "name" $name) }}
  {{- end }}

  {{- /* count int */ -}}
  {{- $count := include "base.getValue" (list . "count") }}
  {{- if $count }}
    {{- include "base.field" (list "count" $count "base.int") }}
  {{- end }}
{{- end }}
