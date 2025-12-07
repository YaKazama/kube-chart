{{- define "service.IngressClass" -}}
  {{- $_ := set . "_kind" "IngressClass" }}

  {{- include "base.field" (list "apiVersion" "networking.k8s.io/v1") }}
  {{- include "base.field" (list "kind" "IngressClass") }}

  {{- /* metadata ObjectMeta */ -}}
  {{- $metadata := include "definitions.ObjectMeta" . | fromYaml }}
  {{- if $metadata }}
    {{- include "base.field" (list "metadata" $metadata "base.map") }}
  {{- end }}

  {{- /* spec IngressClassSpec */ -}}
  {{- $spec := include "service.IngressClassSpec" . | fromYaml }}
  {{- if $spec }}
    {{- include "base.field" (list "spec" $spec "base.map") }}
  {{- end }}
{{- end }}
