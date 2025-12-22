{{- define "workloads.DaemonSetSpec" -}}
  {{- $const := include "base.env" "" | fromYaml }}

  {{- /* minReadySeconds int */ -}}
  {{- $minReadySeconds := include "base.getValue" (list . "minReadySeconds") }}
  {{- if $minReadySeconds }}
    {{- include "base.field" (list "minReadySeconds" $minReadySeconds "base.int") }}
  {{- end }}

  {{- /* revisionHistoryLimit int */ -}}
  {{- $revisionHistoryLimit := include "base.getValue" (list . "revisionHistoryLimit") }}
  {{- if $revisionHistoryLimit }}
    {{- include "base.field" (list "revisionHistoryLimit" $revisionHistoryLimit "base.int") }}
  {{- end }}

  {{- /* selector map */ -}}
  {{- $selectorVal := include "base.getValue" (list . "selector") | fromYaml }}
  {{- $labels := include "base.getValue" . | fromYaml }}
  {{- $_matchLabels := get $selectorVal "matchLabels" }}
  {{- if kindIs "map" $_matchLabels }}
    {{- $_matchLabels = mustMerge $_matchLabels $labels }}
  {{- else }}
    {{- $_matchLabels = $labels }}
  {{- end }}
  {{- /* 设置 matchLabels */ -}}
  {{- $_ := set $selectorVal "matchLabels" $_matchLabels }}
  {{- /* 传递 _kind */ -}}
  {{- $_ := set $selectorVal "_kind" "DeploymentSpec" }}
  {{- $selector := include "definitions.LabelSelector" $selectorVal | fromYaml }}
  {{- if $selector }}
    {{- include "base.field" (list "selector" $selector "base.map") }}
  {{- end }}

  {{- /* template map */ -}}
  {{- /* 透传顶层上下文 . */ -}}
  {{- /* 此处赋值是为了防止上层的 ._kind 被修改 */ -}}
  {{- $templateVal := . }}
  {{- $template := include "metadata.PodTemplateSpec" $templateVal | fromYaml }}
  {{- if $template }}
    {{- include "base.field" (list "template" $template "base.map") }}
  {{- end }}

  {{- /* updateStrategy map */ -}}
  {{- $updateStrategyVal := include "base.getValue" (list . "updateStrategy") }}
  {{- if $updateStrategyVal }}
    {{- $match := regexFindAll $const.k8s.strategy.deamonset $updateStrategyVal -1 }}
    {{- if $match }}
      {{- $type := regexReplaceAll $const.k8s.strategy.deamonset $updateStrategyVal "${1}" | trim }}
      {{- $maxSurge := regexReplaceAll $const.k8s.strategy.deamonset $updateStrategyVal "${2}" | trim }}
      {{- $maxUnavailable := regexReplaceAll $const.k8s.strategy.deamonset $updateStrategyVal "${3}" | trim }}
      {{- $val := dict "type" $type "rollingUpdate" (dict "maxSurge" $maxSurge "maxUnavailable" $maxUnavailable) }}
      {{- $updateStrategy := include "definitions.DaemonSetUpdateStrategy" $val | fromYaml }}
      {{- if $updateStrategy }}
        {{- include "base.field" (list "updateStrategy" $updateStrategy "base.map") }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}
