{{- define "kustomization.ReplacementTarget" -}}
  {{- /* select map */ -}}
  {{- $selectVal := include "base.getValue" (list . "select") | fromYaml }}
  {{- if $selectVal }}
    {{- $select := include "kustomization.PatchesTarget" $selectVal | fromYaml }}
    {{- if $select }}
      {{- include "base.field" (list "select" $select "base.map") }}
    {{- end }}
  {{- end }}

  {{- /* reject array */ -}}
  {{- $rejectVal := include "base.getValue" (list . "reject") | fromYamlArray }}
  {{- $reject := list }}
  {{- range $rejectVal }}
    {{- $reject = append $reject (include "kustomization.PatchesTarget" . | fromYaml) }}
  {{- end }}
  {{- $reject = $reject | mustUniq | mustCompact }}
  {{- if $reject }}
    {{- include "base.field" (list "reject" $reject "base.slice") }}
  {{- end }}

  {{- /* fieldPaths string array */ -}}
  {{- $fieldPaths := include "base.getValue" (list . "fieldPaths") | fromYamlArray }}
  {{- if $fieldPaths }}
    {{- include "base.field" (list "fieldPaths" $fieldPaths "base.slice") }}
  {{- end }}

  {{- /* options map */ -}}
  {{- $optionsVal := include "base.getValue" (list . "options") | fromYaml }}
  {{- if $optionsVal }}
    {{- $options := include "kustomization.ReplacementSourceOption" $optionsVal | fromYaml }}
    {{- if $options }}
      {{- include "base.field" (list "options" $options "base.map") }}
    {{- end }}
  {{- end }}
{{- end }}
