{{- define "configStorage.Volume" -}}
  {{- $typesAllows := list "cm" "configMap" "secret" "pvc" "persistentVolumeClaim" "emptyDir" "hostPath" "nfs" "image" "fc" "iscsi" "local" }}

  {{- /* 检查传入是否为一个键值对 */ -}}
  {{- $keys := keys . }}
  {{- if ne (len $keys) 1 }}
    {{- fail (printf "volume invalid, only allows one key-value pair. Values: %s" .) }}
  {{- end }}

  {{- /* 拆分 key 统一使用冒号分隔符 */ -}}
  {{- $fullKeys := index $keys 0 }}
  {{- $_fullKeys := mustRegexSplit ":" $fullKeys -1 }}
  {{- if lt (len $_fullKeys) 2 }}
    {{- fail (printf "volume key format invalid, format: '<volumeType>:<volumeName>'. Values: %" $fullKeys) }}
  {{- end }}
  {{- $volumeType := index $_fullKeys 0 }}
  {{- $volumeName := include "base.string" (index $_fullKeys 1) | nospace }}

  {{- /* 校验 volumeType 是否合法 */ -}}
  {{- if not (has $volumeType $typesAllows) }}
    {{- fail (printf "volume key type '%s' invalid, allows: '%v'" $volumeType $typesAllows) }}
  {{- end }}
  {{- /* 校验 volumeName 是否为空 */ -}}
  {{- if not (include "base.name" $volumeName) }}
    {{- fail (printf "volume name '%s' invalid, see RFC1035." $volumeName) }}
  {{- end }}

  {{- /* name string */ -}}
  {{- if $volumeName }}
    {{- include "base.field" (list "name" $volumeName) }}
  {{- end }}

  {{- /* 获取原始value */ -}}
  {{- $originalValue := index . $fullKeys }}

  {{- /* configMap map */ -}}
  {{- if or (eq $volumeType "configMap") (eq $volumeType "cm") }}
    {{- $cm := include "definitions.ConfigMapVolumeSource" $originalValue | fromYaml }}
    {{- if $cm }}
      {{- include "base.field" (list "configMap" $cm "base.map") }}
    {{- end }}

  {{- /* emptyDir map */ -}}
  {{- else if eq $volumeType "emptyDir" }}
    {{- if empty $originalValue }}        {{- /* 特殊情况 空 map 不好打印，故此处在外层直接打印输出 */ -}}
      {{- nindent 0 "" -}}emptyDir: {}
    {{- else }}
      {{- $emptyDir := include "definitions.EmptyDirVolumeSource" $originalValue | fromYaml }}
      {{- include "base.field" (list "emptyDir" $emptyDir "base.map") }}
    {{- end }}

  {{- /* fc map */ -}}
  {{- else if eq $volumeType "fc" }}
    {{- $fc := include "definitions.FCVolumeSource" $originalValue | fromYaml }}
    {{- if $fc }}
      {{- include "base.field" (list "fc" $fc "base.map") }}
    {{- end }}

  {{- /* hostPath map */ -}}
  {{- else if eq $volumeType "hostPath" }}
    {{- $hostPath := include "definitions.HostPathVolumeSource" $originalValue | fromYaml }}
    {{- if $hostPath }}
      {{- include "base.field" (list "hostPath" $hostPath "base.map") }}
    {{- end }}

  {{- /* imaage map */ -}}
  {{- else if eq $volumeType "image" }}
    {{- $image := include "definitions.ImageVolumeSource" $originalValue | fromYaml }}
    {{- if $image }}
      {{- include "base.field" (list "image" $image "base.map") }}
    {{- end }}

  {{- /* iscsi map */ -}}
  {{- else if eq $volumeType "iscsi" }}
    {{- $iscsi := include "definitions.ISCSIVolumeSource" $originalValue | fromYaml }}
    {{- if $iscsi }}
      {{- include "base.field" (list "iscsi" $iscsi "base.map") }}
    {{- end }}

  {{- /* nfs map */ -}}
  {{- else if eq $volumeType "nfs" }}
    {{- $nfs := include "definitions.NFSVolumeSource" $originalValue | fromYaml }}
    {{- if $nfs }}
      {{- include "base.field" (list "nfs" $nfs "base.map") }}
    {{- end }}

  {{- /* persistentVolumeClaim map */ -}}
  {{- else if or (eq $volumeType "persistentVolumeClaim") (eq $volumeType "pvc") }}
    {{- $pvc := include "definitions.PersistentVolumeClaimVolumeSource" $originalValue | fromYaml }}
    {{- if $pvc }}
      {{- include "base.field" (list "pvc" $pvc "base.map") }}
    {{- end }}

  {{- /* secret map */ -}}
  {{- else if eq $volumeType "secret" }}
    {{- $secret := include "definitions.SecretVolumeSource" $originalValue | fromYaml }}
    {{- if $secret }}
      {{- include "base.field" (list "secret" $secret "base.map") }}
    {{- end }}

  {{- /* local map */ -}}
  {{- else if eq $volumeType "local" }}
    {{- $local := include "definitions.LocalVolumeSource" $originalValue | fromYaml }}
    {{- if $local }}
      {{- include "base.field" (list "local" $local "base.map") }}
    {{- end }}
  {{- end }}
{{- end }}
