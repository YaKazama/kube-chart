{{- define "metadata.PodTemplate" -}}
  {{- $_ := set . "_kind" "PodTemplate" }}

  {{- include "base.field" (list "apiVersion" "v1") }}
  {{- include "base.field" (list "kind" "PodTemplate") }}

  {{- /* metadata map */ -}}
  {{- $metadata := include "definitions.ObjectMeta" . | fromYaml }}
  {{- if $metadata }}
    {{- include "base.field" (list "metadata" $metadata "base.map") }}
  {{- end }}

  {{- /* template map */ -}}
  {{- $templateVal := include "base.getValue" (list . "template") | fromYaml }}
  {{- $_ := set $templateVal "Values" .Values }}
  {{- $_ := set $templateVal "Context" .Context }}
  {{- $template := include "metadata.PodTemplateSpec" $templateVal | fromYaml }}
  {{- if $template }}
    {{- include "base.field" (list "template" $template "base.map") }}
  {{- end }}
{{- end }}
