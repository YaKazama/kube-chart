{{- define "workloads.StatefulSetSpec" -}}
  {{- $_ := set . "_pkind" (get . "_kind") }}
  {{- $_ := set . "_kind" "StatefulSetSpec" }}
  {{- $__kind := get . "_kind" }}

  {{- /* minReadySeconds int */ -}}
  {{- $minReadySeconds := include "base.getValue" (list . "minReadySeconds") }}
  {{- if $minReadySeconds }}
    {{- include "base.field" (list "minReadySeconds" $minReadySeconds "base.int") }}
  {{- end }}

  {{- /* ordinals map */ -}}
  {{- $ordinalsVal := include "base.getValue" (list . "ordinals") }}
  {{- if $ordinalsVal }}
    {{- $ordinals := include "definitions.StatefulSetOrdinals" $ordinalsVal | fromYaml }}
    {{- if $ordinals }}
      {{- include "base.field" (list "ordinals" $ordinals "base.map") }}
    {{- end }}
  {{- end }}

  {{- /* persistentVolumeClaimRetentionPolicy map */ -}}
  {{- $persistentVolumeClaimRetentionPolicyVal := include "base.getValue" (list . "persistentVolumeClaimRetentionPolicy") }}
  {{- if $persistentVolumeClaimRetentionPolicyVal }}
    {{- $persistentVolumeClaimRetentionPolicy := include "definitions.StatefulSetPersistentVolumeClaimRetentionPolicy" $persistentVolumeClaimRetentionPolicyVal | fromYaml }}
    {{- if $persistentVolumeClaimRetentionPolicy }}
      {{- include "base.field" (list "persistentVolumeClaimRetentionPolicy" $persistentVolumeClaimRetentionPolicy "base.map") }}
    {{- end }}
  {{- end }}

  {{- /* podManagementPolicy string */ -}}
  {{- $podManagementPolicy := include "base.getValue" (list . "podManagementPolicy") }}
  {{- $podManagementPolicyAllows := list "OrderedReady" "Parallel" }}
  {{- if $podManagementPolicy }}
    {{- include "base.field" (list "podManagementPolicy" $podManagementPolicy "base.string" $podManagementPolicyAllows) }}
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
  {{- /* 将 labels helmLabels name 追加到 selector 中一并传入 参考 definitions.ObjectMeta 中的 labels */ -}}
  {{- $labels := include "base.getValue" (list . "labels") | fromYaml }}
  {{- $isHelmLabels := include "base.getValue" (list . "helmLabels") }}
  {{- if $isHelmLabels }}
    {{- $labels = mustMerge $labels (include "base.helmLabels" . | fromYaml) }}
  {{- end }}
  {{- /* 默认增加 name */ -}}
  {{- $name := include "base.name" . }}
  {{- if $name }}
    {{- $labels = mustMerge $labels (include "base.field" (list "name" $name) | fromYaml) }}
  {{- end }}
  {{- if $labels }}
    {{- $_ := set $selectorVal "labels" $labels }}
  {{- end }}
  {{- $selector := include "definitions.LabelSelector" $selectorVal | fromYaml }}
  {{- if $selector }}
    {{- include "base.field" (list "selector" $selector "base.map") }}
  {{- end }}

  {{- /* serviceName string */ -}}
  {{- $serviceName := include "base.getValue" (list . "serviceName") }}
  {{- if $serviceName }}
    {{- include "base.field" (list "serviceName" $serviceName) }}
  {{- end }}

  {{- /* template map */ -}}
  {{- $template := include "metadata.PodTemplateSpec" . | fromYaml }}
  {{- if $template }}
    {{- include "base.field" (list "template" $template "base.map") }}
  {{- end }}

  {{- /* updateStrategy map */ -}}
  {{- $updateStrategyVal := include "base.getValue" (list . "updateStrategy") }}
  {{- if $updateStrategyVal }}
    {{- $updateStrategy := include "definitions.StatefulSetUpdateStrategy" $updateStrategyVal | fromYaml }}
    {{- if $updateStrategy }}
      {{- include "base.field" (list "updateStrategy" $updateStrategy "base.map") }}
    {{- end }}
  {{- end }}

  {{- /* volumeClaimTemplates map */ -}}
  {{- $volumeClaimTemplatesVal := include "base.getValue" (list . "volumeClaimTemplates") | fromYamlArray }}
  {{- $volumeClaimTemplates := list }}
  {{- range $volumeClaimTemplatesVal }}
    {{- if kindIs "string" . }}
      {{- $val := dict }}
      {{- $_ := set $val "_kind" $__kind }}  {{- /* 将当前模板定义的 _kind 向下传递 */ -}}
      {{- $_ := set $val "spec" . }}  {{- /* 抽象成了一个字符串，故此处将值给 spec 然后将 $val 传递给模板定义 */ -}}
      {{- $volumeClaimTemplates = append $volumeClaimTemplates (include "configStorage.PersistentVolumeClaim" $val | fromYaml) }}
    {{- else if kindIs "map" . }}
      {{- $_ := set . "_kind" $__kind }}
      {{- $volumeClaimTemplates = append $volumeClaimTemplates (include "configStorage.PersistentVolumeClaim" . | fromYaml) }}
    {{- end }}
  {{- end }}
  {{- $volumeClaimTemplates = $volumeClaimTemplates | mustUniq | mustCompact }}
  {{- if $volumeClaimTemplates }}
    {{- include "base.field" (list "volumeClaimTemplates" $volumeClaimTemplates "base.slice") }}
  {{- end }}
{{- end }}
