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
  {{- /* 透传顶层上下文 . */ -}}
  {{- /* 此处赋值是为了防止上层的 ._kind 被修改 */ -}}
  {{- $templateVal := . }}
  {{- $template := include "metadata.PodTemplateSpec" $templateVal | fromYaml }}
  {{- if $template }}
    {{- include "base.field" (list "template" $template "base.map") }}
  {{- end }}
{{- end }}
