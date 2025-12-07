{{- define "service.Service" -}}
  {{- $_ := set . "_kind" "Service" }}

  {{- include "base.field" (list "apiVersion" "v1") }}
  {{- include "base.field" (list "kind" "Service") }}

  {{- /* 合并 .Context.service .Context */ -}}
  {{- if and .Context .Context.service (not .Context.services) }}
    {{- $_ := set . "Context" (mustMerge .Context.service .Context) }}
  {{- end }}

  {{- /* metadata ObjectMeta */ -}}
  {{- $metadata := include "definitions.ObjectMeta" . | fromYaml }}
  {{- if $metadata }}
    {{- include "base.field" (list "metadata" $metadata "base.map") }}
  {{- end }}

  {{- /* spec ServiceSpec */ -}}
  {{- $spec := include "service.ServiceSpec" . | fromYaml }}
  {{- if $spec }}
    {{- include "base.field" (list "spec" $spec "base.map") }}
  {{- end }}
{{- end }}
