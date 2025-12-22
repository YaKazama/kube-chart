{{- define "definitions.CrossVersionObjectReference" -}}
  {{- /* apiVersion string */ -}}
  {{- $apiVersion := include "base.getValue" (list . "apiVersion") }}
  {{- if $apiVersion }}
    {{- include "base.field" (list "apiVersion" $apiVersion) }}
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
