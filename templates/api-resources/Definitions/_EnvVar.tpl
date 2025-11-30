{{- define "definitions.EnvVar" -}}
  {{- /* name string */ -}}
  {{- $name := include "base.getValue" (list . "name") }}
  {{- include "base.field" (list "name" $name) }}

  {{- /* value string */ -}}
  {{- /* valueFrom map */ -}}
  {{- $value := include "base.getValue" (list . "value") }}
  {{- $valueFromVal := include "base.getValue" (list . "valueFrom") }}
  {{- if $value }}
    {{- include "base.field" (list "value" $value) }}
  {{- else if $valueFromVal }}
    {{- $valueFrom := include "definitions.EnvVarSource" $valueFromVal | fromYaml }}
    {{- if $valueFrom }}
      {{- include "base.field" (list "valueFrom" $valueFrom "base.map") }}
    {{- end }}
  {{- else }}
    {{- fail "definitions.EnvVar: env.value or env.valueFrom cannot be empty" }}
  {{- end }}
{{- end }}
