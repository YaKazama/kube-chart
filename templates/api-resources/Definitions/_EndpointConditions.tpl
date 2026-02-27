{{- define "definitions.EndpointConditions" -}}
  {{- /* ready bool */ -}}
  {{- $ready := include "base.getValue" (list . "ready") }}
  {{- if $ready }}
    {{- include "base.field" (list "ready" $ready "base.bool") }}
  {{- end }}

  {{- /* serving bool */ -}}
  {{- $serving := include "base.getValue" (list . "serving") }}
  {{- if $serving }}
    {{- include "base.field" (list "serving" $serving "base.bool") }}
  {{- end }}

  {{- /* terminating bool */ -}}
  {{- $terminating := include "base.getValue" (list . "terminating") }}
  {{- if $terminating }}
    {{- include "base.field" (list "terminating" $terminating "base.bool") }}
  {{- end }}
{{- end }}
