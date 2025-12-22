{{- /* vpa v1 */ -}}
{{- define "definitions.EvictionRequirementsItems" -}}
  {{- /* items */ -}}
  {{- $itemsVal := include "base.getValue" (list . "items") | fromYaml }}
  {{- if $itemsVal }}
    {{- $items := include "definitions.EvictionRequirementsItem" $itemsVal | fromYaml }}
    {{- if $items }}
      {{- include "base.field" (list "items" $items "base.map") }}
    {{- end }}
  {{- end }}
{{- end }}
