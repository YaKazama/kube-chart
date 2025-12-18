{{- define "definitions.LocalObjectReference" -}}
  {{- /* name string */ -}}
  {{- $name := include "base.getValue" (list . "name") }}
  {{- if $name }}
    {{- include "base.field" (list "name" $name "base.rfc1035") }}
  {{- end }}
{{- end }}
