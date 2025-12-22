{{- /* vpa v1 */ -}}
{{- define "definitions.ControlledResourcesReference" -}}
  {{- /* items string */ -}}
  {{- $items := include "base.getValue" (list . "items") }}
  {{- if $items }}
    {{- include "base.field" (list "items" $items) }}
  {{- end }}
{{- end }}
