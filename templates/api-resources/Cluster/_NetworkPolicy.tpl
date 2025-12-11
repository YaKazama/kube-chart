{{- define "cluster.NetworkPolicy" -}}
  {{- $_ := set . "_kind" "NetworkPolicy" }}

  {{- include "base.field" (list "apiVersion" "networking.k8s.io/v1") }}
  {{- include "base.field" (list "kind" "NetworkPolicy") }}

  {{- /* metadata map */ -}}
  {{- $metadata := include "definitions.ObjectMeta" . | fromYaml }}
  {{- if $metadata }}
    {{- include "base.field" (list "metadata" $metadata "base.map") }}
  {{- end }}

  {{- $spec := include "cluster.NetworkPolicySpec" . | fromYaml }}
  {{- if $spec }}
    {{- include "base.field" (list "spec" $spec "base.map") }}
  {{- end }}
{{- end }}
