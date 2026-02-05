{{- define "configStorage.PersistentVolumeClaimSpec" -}}
  {{- /* accessModes string array */ -}}
  {{- $accessModes := include "base.getValue" (list . "accessModes") | fromYamlArray }}
  {{- $accessModesAllows := list "ReadWriteOnce" "ReadOnlyMany" "ReadWriteMany" "ReadWriteOncePod" }}
  {{- if $accessModes }}
    {{- if not (has $accessModes $accessModesAllows) }}
      {{- fail (printf "configStorage.PersistentVolumeClaimSpec: accessModes '%s' invalid" $accessModes) }}
    {{- end }}
    {{- include "base.field" (list "accessModes" $accessModes "base.slice") }}
  {{- end }}

  {{- /* dataSource map */ -}}
  {{- /* 理论上，基于 StatefulSet.volumeClaimTemplates 定义的内容，不会有此字段 */ -}}
  {{- $dataSourceVal := include "base.getValue" (list . "dataSource") | fromYaml }}
  {{- if $dataSourceVal }}
    {{- $val := pick $dataSourceVal "apiGroup" "kind" "name" }}
    {{- $dataSource := include "definitions.TypedLocalObjectReference" $val | fromYaml }}
    {{- if $dataSource }}
      {{- include "base.field" (list "dataSource" $dataSource "base.map") }}
    {{- end }}
  {{- end }}

  {{- /* dataSourceRef map */ -}}
  {{- /* 理论上，基于 StatefulSet.volumeClaimTemplates 定义的内容，不会有此字段 */ -}}
  {{- $dataSourceRefVal := include "base.getValue" (list . "dataSourceRef") | fromYaml }}
  {{- if $dataSourceRefVal }}
    {{- $val := pick $dataSourceRefVal "apiGroup" "kind" "name" "namespace" }}
    {{- $dataSourceRef := include "definitions.TypedObjectReference" $val | fromYaml }}
    {{- if $dataSourceRef }}
      {{- include "base.field" (list "dataSourceRef" $dataSourceRef "base.map") }}
    {{- end }}
  {{- end }}

  {{- /* resources map */ -}}
  {{- $resourcesVal := include "base.getValue" (list . "resources") | fromYaml }}
  {{- if $resourcesVal }}
    {{- $resources := include "definitions.VolumeResourceRequirements" $resourcesVal | fromYaml }}
    {{- if $resources }}
      {{- include "base.field" (list "resources" $resources "base.map") }}
    {{- end }}
  {{- end }}

  {{- /* selector map */ -}}
  {{- /* 理论上，基于 StatefulSet.volumeClaimTemplates 定义的内容，不会有此字段 */ -}}
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

  {{- /* storageClassName string */ -}}
  {{- $storageClassName := include "base.getValue" (list . "storageClassName") }}
  {{- if $storageClassName }}
    {{- include "base.field" (list "storageClassName" $storageClassName) }}
  {{- end }}

  {{- /* volumeAttributesClassName string */ -}}
  {{- $volumeAttributesClassName := include "base.getValue" (list . "volumeAttributesClassName") }}
  {{- if $volumeAttributesClassName }}
    {{- include "base.field" (list "volumeAttributesClassName" $volumeAttributesClassName) }}
  {{- end }}

  {{- /* volumeMode string */ -}}
  {{- $volumeMode := include "base.getValue" (list . "volumeMode") }}
  {{- $volumeModeAllows := list "Block" "Filesystem" }}
  {{- if has $volumeMode $volumeModeAllows }}
    {{- include "base.field" (list "volumeMode" $volumeMode) }}
  {{- end }}

  {{- /* volumeName string */ -}}
  {{- $volumeName := include "base.getValue" (list . "volumeName") }}
  {{- if $volumeName }}
    {{- include "base.field" (list "volumeName" $volumeName) }}
  {{- end }}
{{- end }}
