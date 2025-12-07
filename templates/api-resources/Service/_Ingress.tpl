{{- define "service.Ingress" -}}
  {{- $_ := set . "_kind" "Ingress" }}

  {{- include "base.field" (list "apiVersion" "networking.k8s.io/v1") }}
  {{- include "base.field" (list "kind" "Ingress") }}

  {{- /* metadata ObjectMeta */ -}}
  {{- $metadata := include "definitions.ObjectMeta" . | fromYaml }}
  {{- if $metadata }}
    {{- include "base.field" (list "metadata" $metadata "base.map") }}
  {{- end }}

  {{- /* spec IngressSpec */ -}}
  {{- $spec := include "service.IngressSpec" . | fromYaml }}
  {{- if $spec }}
    {{- include "base.field" (list "spec" $spec "base.map") }}
  {{- end }}
{{- end }}
