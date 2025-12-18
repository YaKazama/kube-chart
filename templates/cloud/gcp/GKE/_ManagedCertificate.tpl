{{- define "gke.ManagedCertificate" -}}
  {{- $_ := set . "_kind" "ManagedCertificate" }}

  {{- include "base.field" (list "apiVersion" "networking.gke.io/v1") }}
  {{- include "base.field" (list "kind" "ManagedCertificate") }}

  {{- /* metadata map */ -}}
  {{- $metadata := include "definitions.ObjectMeta" . | fromYaml }}
  {{- if $metadata }}
    {{- include "base.field" (list "metadata" $metadata "base.map") }}
  {{- end }}

  {{- /* spec map */ -}}
  {{- $spec := include "gke.ManagedCertificateSpec" . | fromYaml }}
  {{- if $spec }}
    {{- include "base.field" (list "spec" $spec "base.map") }}
  {{- end }}
{{- end }}
