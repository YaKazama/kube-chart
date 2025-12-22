{{- define "metadata.HorizontalPodAutoscaler" -}}
  {{- $_ := set . "_kind" "HorizontalPodAutoscaler" }}

  {{- include "base.field" (list "apiVersion" "autoscaling/v2") }}
  {{- include "base.field" (list "kind" "HorizontalPodAutoscaler") }}

  {{- /* metadata map */ -}}
  {{- $metadata := include "definitions.ObjectMeta" . | fromYaml }}
  {{- if $metadata }}
    {{- include "base.field" (list "metadata" $metadata "base.map") }}
  {{- end }}

  {{- /* spec map */ -}}
  {{- $spec := include "metadata.HorizontalPodAutoscalerSpec" . | fromYaml }}
  {{- if $spec }}
    {{- include "base.field" (list "spec" $spec "base.map") }}
  {{- end }}
{{- end }}
