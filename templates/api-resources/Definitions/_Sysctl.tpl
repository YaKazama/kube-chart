{{- define "definitions.Sysctl" -}}
  {{- /* name string */ -}}
  {{- $name := include "base.getValue" (list . "name") }}
  {{- if and $name }}
    {{- include "base.field" (list "name" $name) }}
  {{- end }}

  {{- /* value string */ -}}
  {{- $value := include "base.getValue" (list . "value") }}
  {{- if $value }}
    {{- include "base.field" (list "value" $value) }}
  {{- end }}
{{- end }}
