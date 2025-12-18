{{- define "metallb.IPAddressPool" -}}
  {{- $_ := set . "_kind" "IPAddressPool" }}

  {{- include "base.field" (list "apiVersion" "metallb.io/v1beta1") }}
  {{- include "base.field" (list "kind" "IPAddressPool") }}

  {{- /* metadata map */ -}}
  {{- $metadata := include "definitions.ObjectMeta" . | fromYaml }}
  {{- if $metadata }}
    {{- include "base.field" (list "metadata" $metadata "base.map") }}
  {{- end }}

  {{- /* spec map */ -}}
  {{- $spec := include "metallb.IPAddressPoolSpec" . | fromYaml }}
  {{- if $spec }}
    {{- include "base.field" (list "spec" $spec "base.map") }}
  {{- end }}
{{- end }}
