{{- define "workloads.StatefulSetSpec" -}}
  {{- $const := include "base.env" "" | fromYaml }}

  {{- /* minReadySeconds int */ -}}
  {{- $minReadySeconds := include "base.getValue" (list . "minReadySeconds") }}
  {{- if $minReadySeconds }}
    {{- include "base.field" (list "minReadySeconds" $minReadySeconds "base.int") }}
  {{- end }}

  {{- /* ordinals map */ -}}
  {{- $ordinalsVal := include "base.getValue" (list . "ordinals") }}
  {{- if $ordinalsVal }}
    {{- $val := dict "start" $ordinalsVal }}
    {{- $ordinals := include "definitions.StatefulSetOrdinals" $val | fromYaml }}
    {{- if $ordinals }}
      {{- include "base.field" (list "ordinals" $ordinals "base.map") }}
    {{- end }}
  {{- end }}

  {{- /* persistentVolumeClaimRetentionPolicy map */ -}}
  {{- $pvcRetentionPolicyVal := include "base.getValue" (list . "persistentVolumeClaimRetentionPolicy") }}
  {{- if $pvcRetentionPolicyVal }}
      {{- $match := regexFindAll $const.k8s.policy.statefulSetPVCRetention $pvcRetentionPolicyVal -1 }}
      {{- if not $match }}
        {{- fail (printf "workloads.StatefulSetSpec: persistentVolumeClaimRetentionPolicy invalid. Values: %s, format: '[whenDeleted] [whenScaled]'" .) }}
      {{- end }}

      {{- $whenDeleted := regexReplaceAll $const.k8s.policy.statefulSetPVCRetention $pvcRetentionPolicyVal "${1}" | trim | title }}
      {{- $whenScaled := regexReplaceAll $const.k8s.policy.statefulSetPVCRetention $pvcRetentionPolicyVal "${2}" | trim | title }}
      {{- $val := dict "whenDeleted" $whenDeleted "whenScaled" $whenScaled }}

      {{- $pvcRetentionPolicy := include "definitions.StatefulSetPersistentVolumeClaimRetentionPolicy" $val | fromYaml }}
    {{- if $pvcRetentionPolicy }}
      {{- include "base.field" (list "persistentVolumeClaimRetentionPolicy" $pvcRetentionPolicy "base.map") }}
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

  {{- /* serviceName string */ -}}
  {{- $serviceName := include "base.getValue" (list . "serviceName") }}
  {{- if $serviceName }}
    {{- include "base.field" (list "serviceName" $serviceName) }}
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
  {{- $match := regexFindAll $const.k8s.strategy.statefulset $updateStrategyVal -1 }}
  {{- if not $match }}
    {{- fail (printf "workloads.StatefulSetSpec: updateStrategy invalid. Values: '%s', format: '[OnDelete|RollingUpdate] [maxUnavailable] [partition]'" $updateStrategyVal) }}
  {{- end }}
  {{- if $match }}
    {{- /* 相对较简单，一次性处理完成 */ -}}
    {{- $type := regexReplaceAll $const.k8s.strategy.statefulset $updateStrategyVal "${1}" | trim }}
    {{- $_maxUnavailable := regexReplaceAll $const.k8s.strategy.statefulset $updateStrategyVal "${2}" | trim }}
    {{- $_partition := regexReplaceAll $const.k8s.strategy.statefulset $updateStrategyVal "${3}" | trim }}
    {{- $val := dict "type" $type "rollingUpdate" (dict "maxUnavailable" $_maxUnavailable "partition" $_partition) }}

    {{- $updateStrategy := include "definitions.StatefulSetUpdateStrategy" $val | fromYaml }}
    {{- if $updateStrategy }}
      {{- include "base.field" (list "updateStrategy" $updateStrategy "base.map") }}
    {{- end }}
  {{- end }}

  {{- /* volumeClaimTemplates map */ -}}
  {{- $volumeClaimTemplatesVal := include "base.getValue" (list . "volumeClaimTemplates") | fromYamlArray }}
  {{- $volumeClaimTemplates := list }}
  {{- range $volumeClaimTemplatesVal }}
    {{- $val := dict }}
    {{- if kindIs "string" . }}
      {{- $match := regexFindAll $const.k8s.volume.claimTemplates . -1 }}
      {{- if not $match }}
        {{- fail (printf "workloads.StatefulSetSpec: volumeClaimTemplates invalid. Values: '%s', format: '<storageClassName> <name> [namespace] accessMode|accessModes (accessModes, ...) <requests> [limits] [volumeName] [volumeMode]'" .) }}
      {{- end }}

      {{- $storageClassName := regexReplaceAll $const.k8s.volume.claimTemplates . "${1}" | trim }}
      {{- $name := regexReplaceAll $const.k8s.volume.claimTemplates . "${2}" | trim }}
      {{- $namespace := regexReplaceAll $const.k8s.volume.claimTemplates . "${3}" | trim }}
      {{- $accessModes := regexReplaceAll $const.k8s.volume.claimTemplates . "${5}" | trim }}
      {{- $_requests := regexReplaceAll $const.k8s.volume.claimTemplates . "${6}" | trim }}
      {{- $_limits := regexReplaceAll $const.k8s.volume.claimTemplates . "${7}" | trim }}
      {{- $volumeMode := regexReplaceAll $const.k8s.volume.claimTemplates . "${8}" | trim }}
      {{- $volumeName := regexReplaceAll $const.k8s.volume.claimTemplates . "${9}" | trim }}

      {{- $val = dict "storageClassName" $storageClassName "name" $name "namespace" $namespace "accessModes" (include "base.slice.cleanup" (dict "s" $accessModes "r" $const.split.comma)) "resources" (dict "requests" (dict "storage" $_requests) "limits" (dict "storage" $_limits)) "volumeMode" $volumeMode "volumeName" $volumeName "_kind" "StatefulSetSpec" }}

    {{- else if kindIs "map" . }}
      {{- $val = pick . "name" "namespace" "accessModes" "resources" "storageClassName" "volumeMode" "volumeName" "_kind" "StatefulSetSpec" }}

    {{- else }}
      {{- fail (printf "workloads.StatefulSetSpec: volumeClaimTemplates type unsupported. Values: '%s'" .) }}
    {{- end }}

    {{- $volumeClaimTemplates = append $volumeClaimTemplates (include "configStorage.PersistentVolumeClaim" $val | fromYaml) }}
  {{- end }}
  {{- $volumeClaimTemplates = $volumeClaimTemplates | mustUniq | mustCompact }}
  {{- if $volumeClaimTemplates }}
    {{- include "base.field" (list "volumeClaimTemplates" $volumeClaimTemplates "base.slice") }}
  {{- end }}
{{- end }}
