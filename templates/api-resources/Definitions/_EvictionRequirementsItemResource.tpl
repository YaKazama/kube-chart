{{- /* vpa v1 */ -}}
{{- define "definitions.EvictionRequirementsItemResource" -}}
  {{- /* items string */ -}}
  {{- $items := include "base.getValue" (list . "items") }}
  {{- $itemsAllows := list "cpu" "memory" }}
  {{- if $items }}
    {{- include "base.field" (list "items" $items "base.string" $itemsAllows) }}
  {{- end }}
{{- end }}
