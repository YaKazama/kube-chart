{{- define "definitions.Sysctl" -}}
  {{- $name := include "base.getValue" (list . "name") }}
  {{- $value := include "base.getValue" (list . "value") }}

  {{- if and $name $value }}
    {{- /* name */ -}}
    {{- include "base.field" (list "name" $name) }}

    {{- /* value */ -}}
    {{- include "base.field" (list "value" $value) }}
  {{- end }}
{{- end }}
