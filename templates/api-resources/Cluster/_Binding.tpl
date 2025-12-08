{{- define "cluster.Binding" -}}
  {{- $_ := set . "_kind" "Binding" }}

  {{- include "base.field" (list "apiVersion" "v1") }}
  {{- include "base.field" (list "kind" "Binding") }}

  {{- /* metadata map */ -}}
  {{- $metadata := include "definitions.ObjectMeta" . | fromYaml }}
  {{- if $metadata }}
    {{- include "base.field" (list "metadata" $metadata "base.map") }}
  {{- end }}

  {{- /* target map */ -}}
  {{- $targetVal := include "base.getValue" (list . "target") | fromYaml }}
  {{- if $targetVal }}
    {{- $target := include "definitions.ObjectReference" $targetVal | fromYaml }}
    {{- if $target }}
      {{- include "base.field" (list "target" $target "base.map") }}
    {{- end }}
  {{- end }}
{{- end }}
