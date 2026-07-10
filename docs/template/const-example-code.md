{{- /* 单行注释 */ -}}
{{- /*
  多行注释
  多行注释
*/ -}}

{{- /* apiVersion 和 kind 字段 */ -}}
{{- nindent 0 "" -}}apiVersion: "meta/v1"
{{- nindent 0 "" -}}kind: "APIGroup"

{{- /* metadata 字段, 示例 */ -}}
{{- $metadata := include "definitions.ObjectMeta" . | fromYaml }}
{{- if $metadata }}
  {{- include "base.field" (list "metadata" $metadata "base.map") }}
{{- end }}

{{- /* 组装 dict 并向下传递，正则拆分字符串取值并向下传递 */ -}}
{{- $const := include "base.env" "" | fromYaml }}
{{- $name := regexReplaceAll $const.k8s.volume.configMap $volumeData "${1}" | trim | lower  }}
{{- $optional := regexReplaceAll $const.k8s.volume.configMap $volumeData "${2}" | trim }}
{{- $defaultMode := regexReplaceAll $const.k8s.volume.configMap $volumeData "${3}" | trim }}
{{- $items := regexSplit $const.split.comma (regexReplaceAll $const.k8s.volume.configMap $volumeData "${4}" | trim) -1 }}
{{- $val := dict "name" $name "optional" $optional "defaultMode" $defaultMode "items" $items }}
{{- $cm := include "definitions.A" $val | fromYaml }}
