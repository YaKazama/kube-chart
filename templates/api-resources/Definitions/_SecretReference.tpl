{{- define "definitions.SecretReference" -}}
  {{- /* name string */ -}}
  {{- $name := include "base.getValue" (list . "name") }}
  {{- if $name }}
    {{- include "base.field" (list "name" $name "base.name") }}
  {{- end }}

  {{- /* namespace string */ -}}
  {{- $namespace := include "base.getValue" (list . "namespace") }}
  {{- if $namespace }}
    {{- include "base.field" (list "namespace" $namespace "base.namespace") }}
  {{- end }}
{{- end }}
