{{- define "kustomization.GeneratorOption" -}}
  {{- /* labels object/map */ -}}
  {{- $labels := include "base.getValue" (list . "labels") | fromYaml }}
  {{- if $labels }}
    {{- include "base.field" (list "labels" $labels "base.map") }}
  {{- end }}

  {{- /* annotations object/map */ -}}
  {{- $annotations := include "base.getValue" (list . "annotations") | fromYaml }}
  {{- if $annotations }}
    {{- include "base.field" (list "annotations" $annotations "base.map") }}
  {{- end }}

  {{- /* disableNameSuffixHash bool */ -}}
  {{- $disableNameSuffixHash := include "base.getValue" (list . "disableNameSuffixHash") }}
  {{- if $disableNameSuffixHash }}
    {{- include "base.field" (list "disableNameSuffixHash" $disableNameSuffixHash "base.bool") }}
  {{- end }}

  {{- /* immutable bool */ -}}
  {{- $immutable := include "base.getValue" (list . "immutable") }}
  {{- if $immutable }}
    {{- include "base.field" (list "immutable" $immutable "base.bool") }}
  {{- end }}
{{- end }}
