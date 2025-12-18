{{- define "tke.TkeServiceConfig" -}}
  {{- $_ := set . "_kind" "TkeServiceConfig" }}

  {{- include "base.field" (list "apiVersion" "cloud.tencent.com/v1alpha1") }}
  {{- include "base.field" (list "kind" "TkeServiceConfig") }}

  {{- /* metadata map */ -}}
  {{- $metadata := include "definitions.ObjectMeta" . | fromYaml }}
  {{- if $metadata }}
    {{- include "base.field" (list "metadata" $metadata "base.map") }}
  {{- end }}

  {{- /* spec map */ -}}
  {{- $_l4 := include "base.getValue" (list . "l4Listeners") }}
  {{- $_l7 := include "base.getValue" (list . "l7Listeners") }}
  {{- $specVal := dict "loadBalancer" (dict "l4Listeners" $_l4 "l7Listeners" $_l7) }}
  {{- $spec := include "tke.TkeServiceConfigSpec" $specVal | fromYaml }}
  {{- if $spec }}
    {{- include "base.field" (list "spec" $spec "base.map") }}
  {{- end }}
{{- end }}
