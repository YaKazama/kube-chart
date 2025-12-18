{{- define "kustomization.LegacySort" -}}
  {{- /* orderFirst string array */ -}}
  {{- $orderFirst := include "base.getValue" (list . "orderFirst") | fromYamlArray }}
  {{- if $orderFirst }}
    {{- include "base.field" (list "orderFirst" $orderFirst "base.slice") }}
  {{- end }}

  {{- /* orderLast string array */ -}}
  {{- $orderLast := include "base.getValue" (list . "orderLast") | fromYamlArray }}
  {{- if $orderLast }}
    {{- include "base.field" (list "orderLast" $orderLast "base.slice") }}
  {{- end }}
{{- end }}
