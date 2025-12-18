{{- define "kustomization.LabelSelector" -}}
  {{- /* pairs object/map */ -}}
  {{- $pairs := include "base.getValue" (list . "pairs") | fromYaml }}
  {{- if $pairs }}
    {{- include "base.field" (list "pairs" $pairs "base.map") }}
  {{- end }}

  {{- /* includeSelectors bool */ -}}
  {{- $includeSelectors := include "base.getValue" (list . "includeSelectors") }}
  {{- if $includeSelectors }}
    {{- include "base.field" (list "includeSelectors" $includeSelectors "base.bool") }}
  {{- end }}

  {{- /* includeTemplates bool */ -}}
  {{- $includeTemplates := include "base.getValue" (list . "includeTemplates") }}
  {{- if $includeTemplates }}
    {{- include "base.field" (list "includeTemplates" $includeTemplates "base.bool") }}
  {{- end }}
{{- end }}
