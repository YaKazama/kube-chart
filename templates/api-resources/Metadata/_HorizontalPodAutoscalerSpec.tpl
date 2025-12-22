{{- define "metadata.HorizontalPodAutoscalerSpec" -}}
  {{- /* behavior map */ -}}
  {{- $behaviorVal := include "base.getValue" (list . "behavior") | fromYaml }}
  {{- if $behaviorVal }}
    {{- $behavior := include "definitions.HorizontalPodAutoscalerBehavior" $behaviorVal | fromYaml }}
    {{- if $behavior }}
      {{- include "base.field" (list "behavior" $behavior "base.map") }}
    {{- end }}
  {{- end }}

  {{- /* maxReplicas int */ -}}
  {{- $maxReplicas := include "base.getValue" (list . "maxReplicas") }}
  {{- if $maxReplicas }}
    {{- include "base.field" (list "maxReplicas" $maxReplicas "base.int") }}
  {{- end }}

  {{- /* metrics array */ -}}
  {{- $metricsVal := include "base.getValue" (list . "metrics") | fromYamlArray }}
  {{- $metrics := list }}
  {{- range $metricsVal }}
    {{- $metrics = append $metrics (include "definitions.MetricSpec" . | fromYaml) }}
  {{- end }}
  {{- $metrics = $metrics | mustUniq | mustCompact }}
  {{- if $metrics }}
    {{- include "base.field" (list "metrics" $metrics "base.slice") }}
  {{- end }}

  {{- /* minReplicas int */ -}}
  {{- $minReplicas := include "base.getValue" (list . "minReplicas") }}
  {{- if $minReplicas }}
    {{- include "base.field" (list "minReplicas" $minReplicas "base.int") }}
  {{- end }}

  {{- /* scaleTargetRef map */ -}}
  {{- $scaleTargetRefVal := include "base.getValue" (list . "scaleTargetRef") | fromYaml }}
  {{- if $scaleTargetRefVal }}
    {{- $scaleTargetRef := include "definitions.CrossVersionObjectReference" $scaleTargetRefVal | fromYaml }}
    {{- if $scaleTargetRef }}
      {{- include "base.field" (list "scaleTargetRef" $scaleTargetRef "base.map") }}
    {{- end }}
  {{- end }}
{{- end }}
