{{- define "workloads.DeploymentSpec" -}}
  {{- $const := include "base.env" "" | fromYaml }}

  {{- /* minReadySeconds int */ -}}
  {{- $minReadySeconds := include "base.getValue" (list . "minReadySeconds") }}
  {{- if $minReadySeconds }}
    {{- include "base.field" (list "minReadySeconds" $minReadySeconds "base.int") }}
  {{- end }}

  {{- /* progressDeadlineSeconds int */ -}}
  {{- $progressDeadlineSeconds := include "base.getValue" (list . "progressDeadlineSeconds") }}
  {{- if $progressDeadlineSeconds }}
    {{- include "base.field" (list "progressDeadlineSeconds" $progressDeadlineSeconds "base.int") }}
  {{- end }}

  {{- /* replicas int */ -}}
  {{- $replicas := include "base.getValue" (list . "replicas") }}
  {{- if $replicas }}
    {{- include "base.field" (list "replicas" $replicas "base.int") }}
  {{- end }}

  {{- /* revisionHistoryLimit int */ -}}
  {{- $revisionHistoryLimit := include "base.getValue" (list . "revisionHistoryLimit") }}
  {{- if $revisionHistoryLimit }}
    {{- include "base.field" (list "revisionHistoryLimit" $revisionHistoryLimit "base.int") }}
  {{- end }}

  {{- /* selector map */ -}}
  {{- $selectorVal := include "base.getValue" (list . "selector") | fromYaml }}
  {{- $labels := include "base.labels" . | fromYaml }}
  {{- $_matchLabels := get $selectorVal "matchLabels" }}
  {{- if kindIs "map" $_matchLabels }}
    {{- $_matchLabels = mustMerge $_matchLabels $labels }}
  {{- else }}
    {{- $_matchLabels = $labels }}
  {{- end }}
  {{- /* 设置 matchLabels */ -}}
  {{- $_ := set $selectorVal "matchLabels" $_matchLabels }}
  {{- $selector := include "definitions.LabelSelector" $selectorVal | fromYaml }}
  {{- if $selector }}
    {{- include "base.field" (list "selector" $selector "base.map") }}
  {{- end }}

  {{- /* strategy map */ -}}
  {{- /* 为空或未定义时，使用默认设置 RollingUpdate 25% 25% */ -}}
  {{- $strategyVal := include "base.getValue" (list . "strategy") }}
  {{- $match := regexFindAll $const.k8s.strategy.deployment $strategyVal -1 }}
  {{- if $match }}
    {{- /* 相对较简单，一次性处理完成 */ -}}
    {{- $type := regexReplaceAll $const.k8s.strategy.deployment $strategyVal "${1}" }}
    {{- $maxSurge := regexReplaceAll $const.k8s.strategy.deployment $strategyVal "${2}" }}
    {{- $maxUnavailable := regexReplaceAll $const.k8s.strategy.deployment $strategyVal "${3}" }}
    {{- $val := dict "type" $type "rollingUpdate" (dict "maxSurge" $maxSurge "maxUnavailable" $maxUnavailable) }}

    {{- $strategy := include "workloads.DeploymentStrategy" $val | fromYaml }}
    {{- if $strategy }}
      {{- include "base.field" (list "strategy" $strategy "base.map") }}
    {{- end }}
  {{- end }}

  {{- /* template PodTemplateSpec */ -}}
  {{- /* 透传顶层上下文 . */ -}}
  {{- /* 此处赋值是为了防止上层的 ._kind 被修改 */ -}}
  {{- $templateVal := . }}
  {{- $template := include "metadata.PodTemplateSpec" $templateVal | fromYaml }}
  {{- if $template }}
    {{- include "base.field" (list "template" $template "base.map") }}
  {{- end }}
{{- end }}
