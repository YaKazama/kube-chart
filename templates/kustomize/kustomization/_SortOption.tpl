{{- define "kustomization.SortOption" -}}
  {{- /* order string */ -}}
  {{- $order := include "base.getValue" (list . "order") }}
  {{- $orderAllows := list "legacy" "fifo" }}
  {{- if $order }}
    {{- include "base.field" (list "order" $order "base.string" $orderAllows) }}
  {{- end }}

  {{- /* legacySortOptions map */ -}}
  {{- if eq $order "legacy" }}
    {{- $legacySortOptionsVal := include "base.getValue" (list . "legacySortOptions") | fromYaml }}
    {{- if $legacySortOptionsVal }}
      {{- $legacySortOptions := include "kustomization.LegacySort" $legacySortOptionsVal | fromYaml }}
      {{- if $legacySortOptions }}
        {{- include "base.field" (list "legacySortOptions" $legacySortOptions "base.map") }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}
