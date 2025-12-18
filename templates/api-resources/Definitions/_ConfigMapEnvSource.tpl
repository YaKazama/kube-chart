{{- define "definitions.ConfigMapEnvSource" -}}
  {{- /* name string */ -}}
  {{- $name := include "base.getValue" (list . "name") }}
  {{- if $name }}
    {{- include "base.field" (list "name" $name) }}
  {{- end }}

  {{- /* optional bool */ -}}
  {{- $optional := include "base.getValue" (list . "optional") }}
  {{- if $optional }}
    {{- include "base.field" (list "optional" $optional "base.bool") }}
  {{- end }}
{{- end }}
