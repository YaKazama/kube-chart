{{- define "metallb.L2Advertisement" -}}
  {{- $_ := set . "_kind" "L2Advertisement" }}

  {{- include "base.field" (list "apiVersion" "metallb.io/v1beta1") }}
  {{- include "base.field" (list "kind" "L2Advertisement") }}

  {{- /* metadata map */ -}}
  {{- $metadata := include "definitions.ObjectMeta" . | fromYaml }}
  {{- if $metadata }}
    {{- include "base.field" (list "metadata" $metadata "base.map") }}
  {{- end }}

  {{- /* spec map */ -}}
  {{- $spec := include "metallb.L2AdvertisementSpec" . | fromYaml }}
  {{- if $spec }}
    {{- include "base.field" (list "spec" $spec "base.map") }}
  {{- end }}
{{- end }}
