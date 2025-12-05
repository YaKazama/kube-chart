{{- define "configStorage.PersistentVolumeClaimSpec" -}}
  {{- if kindIs "string" . }}
    {{- $regex := "^(\\S+)\\s+(\\S+)(?:\\s+(\\S+))?\\s+(accessModes?)\\s*\\(\\s*([^)]+?)\\s*\\)\\s+(\\S+)(?:\\s+(\\S+))?(?:\\s+(\\S+))?(?:\\s+(Filesystem|filesystem|Block|block))?$" }}

    {{- $match := regexFindAll $regex . -1 }}
    {{- if not $match }}
      {{- fail (printf "PersistentVolumeClaimSpec: error. Values: %s, format: '<storageClassName> <name> [namespace] accessMode|accessModes (accessModes, ...) <requests> [limits] [volumeName] [volumeMode]'" .) }}
    {{- end }}

    {{- /* accessModes string array */ -}}
    {{- $accessModes := regexReplaceAll $regex . "${5}" }}
    {{- if $accessModes }}
      {{- include "base.field" (list "accessModes" (dict "s" $accessModes "r" ",\\s*") "base.slice.cleanup") }}
    {{- end }}

    {{- /* dataSource map */ -}}

    {{- /* dataSourceRef map */ -}}

    {{- /* resources map */ -}}
    {{- $_requests := regexReplaceAll $regex . "${6}" }}
    {{- $_limits := regexReplaceAll $regex . "${7}" }}
    {{- if or $_requests $_limits }}
      {{- $val := dict }}
      {{- $_ := set $val "requests" $_requests }}
      {{- $_ := set $val "limits" $_limits }}
      {{- $resources := include "definitions.VolumeResourceRequirements" $val | fromYaml }}
      {{- if $resources }}
        {{- include "base.field" (list "resources" $resources "base.map") }}
      {{- end }}
    {{- end }}

    {{- /* selector map */ -}}

    {{- /* storageClassName string */ -}}
    {{- $storageClassName := regexReplaceAll $regex . "${1}" }}
    {{- if $storageClassName }}
      {{- include "base.field" (list "storageClassName" $storageClassName) }}
    {{- end }}

    {{- /* volumeAttributesClassName string */ -}}

    {{- /* volumeMode string */ -}}
    {{- $volumeMode := regexReplaceAll $regex . "${8}" }}
    {{- if $volumeMode }}
      {{- include "base.field" (list "volumeMode" $volumeMode) }}
    {{- end }}

    {{- /* volumeName string */ -}}
    {{- $volumeName := regexReplaceAll $regex . "${9}" }}
    {{- if $volumeName }}
      {{- include "base.field" (list "volumeName" $volumeName) }}
    {{- end }}

  {{- else if kindIs "map" . }}
      {{- /* accessModes string array */ -}}
      {{- $accessModes := include "base.getValue" (list . "accessModes") | fromYamlArray }}
      {{- if $accessModes }}
        {{- include "base.field" (list "accessModes" $accessModes "base.slice") }}
      {{- end }}

      {{- /* dataSource map */ -}}
      {{- $dataSourceVal := include "base.getValue" (list . "dataSource") | fromYaml }}
      {{- if $dataSourceVal }}
        {{- $dataSource := include "definitions.TypedLocalObjectReference" $dataSourceVal | fromYaml }}
        {{- if $dataSource }}
          {{- include "base.field" (list "dataSource" $dataSource "base.map") }}
        {{- end }}
      {{- end }}

      {{- /* dataSourceRef map */ -}}
      {{- $dataSourceRefVal := include "base.getValue" (list . "dataSourceRef") | fromYaml }}
      {{- if $dataSourceRefVal }}
        {{- $dataSourceRef := include "definitions.TypedObjectReference" $dataSourceRefVal | fromYaml }}
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
      {{- if $volumeMode }}
        {{- include "base.field" (list "volumeMode" $volumeMode) }}
      {{- end }}

      {{- /* volumeName string */ -}}
      {{- $volumeName := include "base.getValue" (list . "volumeName") }}
      {{- if $volumeName }}
        {{- include "base.field" (list "volumeName" $volumeName) }}
      {{- end }}
  {{- end }}
{{- end }}
