{{- /*
  vpa v1
  参考 https://github.com/kubernetes/autoscaler/blob/master/vertical-pod-autoscaler/deploy/vpa-v1-crd-gen.yaml
*/ -}}
{{- define "metadata.VerticalPodAutoscalerSpec" -}}
  {{- /* recommenders array */ -}}
  {{- $recommendersVal := include "base.getValue" (list . "recommenders") | fromYamlArray }}
  {{- $recommenders := list }}
  {{- range $recommendersVal }}
    {{- $val := dict "name" . }}
    {{- $recommenders = append $recommenders (include "definitions.VerticalPodAutoscalerRecommender" $val | fromYaml) }}
  {{- end }}
  {{- $recommenders = $recommenders | mustUniq | mustCompact }}
  {{- if $recommenders }}
    {{- include "base.field" (list "recommenders" $recommenders "base.slice") }}
  {{- end }}

  {{- /* resourcePolicy map */ -}}
  {{- $resourcePolicyVal := include "base.getValue" (list . "resourcePolicy") | fromYaml }}
  {{- if $resourcePolicyVal }}
    {{- $resourcePolicy := include "definitions.VerticalPodAutoscalerResourcePolicy" $resourcePolicyVal | fromYaml }}
    {{- if $resourcePolicy }}
      {{- include "base.field" (list "resourcePolicy" $resourcePolicy "base.map") }}
    {{- end }}
  {{- end }}

  {{- /* targetRef map */ -}}
  {{- $targetRefVal := include "base.getValue" (list . "targetRef") | fromYaml }}
  {{- if $targetRefVal }}
    {{- $targetRef := include "definitions.VerticalPodAutoscalerTargetRef" $targetRefVal | fromYaml }}
    {{- if $targetRef }}
      {{- include "base.field" (list "targetRef" $targetRef "base.map") }}
    {{- end }}
  {{- end }}

  {{- /* updatePolicy map */ -}}
  {{- $updatePolicyVal := include "base.getValue" (list . "updatePolicy") | fromYaml }}
  {{- if $updatePolicyVal }}
    {{- $updatePolicy := include "definitions.VerticalPodAutoscalerUpdatePolicy" $updatePolicyVal | fromYaml }}
    {{- if $updatePolicy }}
      {{- include "base.field" (list "updatePolicy" $updatePolicy "base.map") }}
    {{- end }}
  {{- end }}
{{- end }}
