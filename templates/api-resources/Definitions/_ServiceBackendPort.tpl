{{- define "definitions.ServiceBackendPort" -}}
  {{- $name := include "base.getValue" (list . "name") }}
  {{- $number := include "base.getValue" (list . "number") }}

  {{- /* name 和 number 互斥 */ -}}
  {{- if $name }}
    {{- /* name string */ -}}
    {{- if $name }}
      {{- include "base.field" (list "name" $name) }}
    {{- end }}

  {{- else if $number }}
    {{- /* number int */ -}}
    {{- if $number }}
      {{- include "base.field" (list "number" $number "base.port") }}
    {{- end }}
  {{- end }}
{{- end }}
