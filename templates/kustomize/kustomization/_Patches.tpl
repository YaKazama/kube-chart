{{- define "kustomization.Patches" -}}
  {{- /* path string */ -}}
  {{- $path := include "base.getValue" (list . "path") }}
  {{- if $path }}
    {{- include "base.field" (list "path" $path) }}
  {{- end }}

  {{- /* patch string */ -}}
  {{- /* todo */ -}}
  {{- $patch := include "base.getValue" (list . "patch") }}
  {{- if $patch }}
    {{- include "base.field" (list "patch" $patch) }}
  {{- end }}

  {{- /* target map */ -}}
  {{- $targetVal := include "base.getValue" (list . "target") | fromYaml }}
  {{- if $targetVal }}
    {{- $val := pick $targetVal "group" "version" "kind" "name" "labelSelector" "annotationSelector" }}
    {{- $target := include "kustomization.PatchesTarget" $val | fromYaml }}
    {{- if $target }}
      {{- include "base.field" (list "target" $target "base.map") }}
    {{- end }}
  {{- end }}

  {{- /* options map */ -}}
  {{- $optionsVal := include "base.getValue" (list . "options") | fromYaml }}
  {{- if $optionsVal }}
    {{- $val := pick $optionsVal "allowNameChange" "allowKindChange" }}
    {{- $options := include "kustomization.PatchesOption" $val | fromYaml }}
    {{- if $options }}
      {{- include "base.field" (list "options" $options "base.map") }}
    {{- end }}
  {{- end }}
{{- end }}
