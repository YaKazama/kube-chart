{{- define "workloads.DeploymentSpec" -}}
  {{- $_ := set . "_pkind" (get . "_kind") }}
  {{- $_ := set . "_kind" "DeploymentSpec" }}

  {{- /* minReadySeconds int */ -}}
  {{- $minReadySeconds := include "base.getValue" (list . "minReadySeconds") }}
  {{- if $minReadySeconds }}
    {{- include "base.field" (list "minReadySeconds" $minReadySeconds "base.int") }}
  {{- end }}

  {{- /* minReadySeconds */ -}}
  {{- $progressDeadlineSeconds := include "base.getValue" (list . "progressDeadlineSeconds") }}
  {{- if $progressDeadlineSeconds }}
    {{- include "base.field" (list "progressDeadlineSeconds" $progressDeadlineSeconds "base.int") }}
  {{- end }}

  {{- /* replicas */ -}}
  {{- $replicas := include "base.getValue" (list . "replicas") }}
  {{- if $replicas }}
    {{- include "base.field" (list "replicas" $replicas "base.int") }}
  {{- end }}

  {{- /* revisionHistoryLimit */ -}}
  {{- $revisionHistoryLimit := include "base.getValue" (list . "revisionHistoryLimit") }}
  {{- if $revisionHistoryLimit }}
    {{- include "base.field" (list "revisionHistoryLimit" $revisionHistoryLimit "base.int") }}
  {{- end }}

  {{- /* selector LabelSelector */ -}}
  {{- $selectorVal := include "base.getValue" (list . "selector") | fromYaml }}
  {{- /* 将 labels helmLabels name 追加到 selector 中一并传入 参考 definitions.ObjectMeta 中的 labels */ -}}
  {{- $labels := include "base.getValue" (list . "labels") | fromYaml }}
  {{- $isHelmLabels := include "base.getValue" (list . "helmLabels") }}
  {{- if $isHelmLabels }}
    {{- $labels = mustMerge $labels (include "base.helmLabels" . | fromYaml) }}
  {{- end }}
  {{- if $labels }}
    {{- $_ := set $selectorVal "labels" $labels }}
  {{- end }}
  {{- $selector := include "definitions.LabelSelector" $selectorVal | fromYaml }}
  {{- if $selector }}
    {{- include "base.field" (list "selector" $selector "base.map") }}
  {{- end }}

  {{- /* strategy map */ -}}
  {{- /* 为空或未定义时，使用默认设置 RollingUpdate 25% 25% */ -}}
  {{- $strategyVal := include "base.getValue" (list . "strategy") }}
  {{- if $strategyVal }}
    {{- $strategy := include "workloads.DeploymentStrategy" $strategyVal | fromYaml }}
    {{- if $strategy }}
      {{- include "base.field" (list "strategy" $strategy "base.map") }}
    {{- end }}
  {{- end }}

  {{- /* template PodTemplateSpec */ -}}
  {{- $template := include "metadata.PodTemplateSpec" . | fromYaml }}
  {{- if $template }}
    {{- include "base.field" (list "template" $template "base.map") }}
  {{- end }}
{{- end }}
