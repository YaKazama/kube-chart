{{- /*
  数据格式：
    - map[_kind: string spec: string]
*/ -}}
{{- define "configStorage.PersistentVolumeClaim" -}}
  {{- $_ := set . "_pkind" (get . "_kind") }}
  {{- $_ := set . "_kind" "PersistentVolumeClaim" }}
  {{- $_spec := get . "spec" }}

  {{- /* apiVersion string */ -}}
  {{- include "base.field" (list "apiVersion" "v1") }}

  {{- /* kind string */ -}}
  {{- include "base.field" (list "kind" "PersistentVolumeClaim") }}

  {{- if $_spec }}
    {{- /* 此处因为 $_spec 是个字符串，故需要将 name 和 namespace 单独处理 */ -}}
    {{- if eq ._pkind "StatefulSetSpec" }}
      {{- $const := include "base.env" "" | fromYaml }}

      {{- $match := regexFindAll $const.regexPersistentVolumeClaim $_spec -1 }}
      {{- if not $match }}
        {{- fail (printf "PersistentVolumeClaim: error. Values: %s, format: 'name [namespace] with|With (mode, ...) [storageClassName] requests [limits] [volumeName] [volumeMode]'" $_spec) }}
      {{- end }}

      {{- $_ := set . "name" (regexReplaceAll $const.regexPersistentVolumeClaim $_spec "${2}") }}
      {{- $_ := set . "namespace" (regexReplaceAll $const.regexPersistentVolumeClaim $_spec "${3}") }}
    {{- end }}
    {{- $metadata := include "definitions.ObjectMeta" . | fromYaml }}
    {{- if $metadata }}
      {{- include "base.field" (list "metadata" $metadata "base.map") }}
    {{- end }}

    {{- /* spec map */ -}}
    {{- /* 会将 _pkind 继续向下传递，但目前没有使用 -- 202512 */ -}}
    {{- if $_spec }}
      {{- $spec := include "configStorage.PersistentVolumeClaimSpec" $_spec | fromYaml }}
      {{- if $spec }}
        {{- include "base.field" (list "spec" $spec "base.map") }}
      {{- end }}
    {{- end }}

  {{- else if kindIs "map" . }}
    {{- /* metadata map */ -}}
    {{- $metadata := include "definitions.ObjectMeta" . | fromYaml }}
    {{- if $metadata }}
      {{- include "base.field" (list "metadata" $metadata "base.map") }}
    {{- end }}

    {{- /* spec map */ -}}
    {{- $spec := include "configStorage.PersistentVolumeClaimSpec" . | fromYaml }}
    {{- if $spec }}
      {{- include "base.field" (list "spec" $spec "base.map") }}
    {{- end }}
  {{- end }}
{{- end }}
