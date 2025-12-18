{{- define "definitions.SecretReference" -}}
  {{- /* name string */ -}}
  {{- $name := include "base.getValue" (list . "name") }}
  {{- if $name }}
    {{- include "base.field" (list "name" $name "base.rfc1035") }}
  {{- end }}

  {{- /* namespace string */ -}}
  {{- $namespace := include "base.getValue" (list . "namespace") }}
  {{- if $namespace }}
    {{- include "base.field" (list "namespace" $namespace "base.namespace") }}
  {{- end }}
{{- end }}
