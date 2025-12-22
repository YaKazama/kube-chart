{{- /* vpa v1 */ -}}
{{- define "metadata.VerticalPodAutoscaler" -}}
  {{- $_ := set . "_kind" "VerticalPodAutoscaler" }}

  {{- include "base.field" (list "apiVersion" "autoscaling.k8s.io/v1") }}
  {{- include "base.field" (list "kind" "VerticalPodAutoscaler") }}

  {{- /* metadata map */ -}}
  {{- $metadata := include "definitions.ObjectMeta" . | fromYaml }}
  {{- if $metadata }}
    {{- include "base.field" (list "metadata" $metadata "base.map") }}
  {{- end }}

  {{- /* spec map */ -}}
  {{- $spec := include "metadata.VerticalPodAutoscalerSpec" . | fromYaml }}
  {{- if $spec }}
    {{- include "base.field" (list "spec" $spec "base.map") }}
  {{- end }}
{{- end }}
