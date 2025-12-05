{{- define "workloads.DaemonSetSpec" -}}
  {{- $_ := set . "_pkind" (get . "_kind") }}
  {{- $_ := set . "_kind" "DaemonSetSpec" }}
  {{- $__kind := get . "_kind" }}

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

  {{- /* template map */ -}}
  {{- $template := include "metadata.PodTemplateSpec" . | fromYaml }}
  {{- if $template }}
    {{- include "base.field" (list "template" $template "base.map") }}
  {{- end }}
{{- end }}
