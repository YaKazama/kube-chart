{{- /*
  渲染 Kubernetes ProjectedVolumeSource 字段片段。

  行为 (按 K8s API 规范字段顺序):
    - defaultMode (integer, 可选): 接受八进制 0000-0777 或十进制 0-511 的数值/字符串，归一化为十进制 int 输出；空值省略。
    - sources     (VolumeProjection array, 可选): 只接受原生 map 数组；每个条目委托 definitions.volumeProjection 渲染，空结果剔除，完全相同的结果保留首个；空数组或全空结果省略。

  边界:
    - 只读取 defaultMode 与 sources，其他字段静默忽略；按 API 顺序输出已生效字段。
    - sources 不是数组、条目不是 map 或子模板输出非法 YAML 时中断。
    - definitions.volumeProjection 当前不可用且不在本 change 创建，只保留调用占位；其输出为空时跳过该条目。

  入参: map，形如 `{defaultMode: "0644", sources: [{secret: {name: "app"}}]}`。

  返回值: 可嵌入 Volume.projected 位置的 YAML 字段片段。

  示例:
    {{- include "definitions.projectedVolumeSource" (dict "defaultMode" "0644") }}
      // defaultMode: 420
    {{- include "definitions.projectedVolumeSource" (dict "defaultMode" 0 "sources" (list (dict "secret" (dict "name" "app")))) }}
      // defaultMode: 0
      // sources:
      //   - ...
*/ -}}
{{- define "definitions.projectedVolumeSource" -}}
  {{- $const := include "base.env" "" | fromYaml }}

  {{- /* defaultMode（integer, 可选）: 剥离 YAML 引号后归一化为十进制 int，显式 0 有效。 */ -}}
  {{- $_defaultModeRaw := include "base.get" (list . "defaultMode") | trim }}
  {{- if $_defaultModeRaw }}
    {{- $defaultMode := mustRegexReplaceAll $const.SYS.YAML_QUOTED $_defaultModeRaw "$1" | trim }}
    {{- if $defaultMode }}
      {{- include "base.field" (list "defaultMode" (include "base.fileMode" $defaultMode) "base.int") }}
    {{- end }}
  {{- end }}

  {{- /* sources（VolumeProjection array, 可选）: 原生 map 逐项委托，空结果剔除并去重；空数组省略。 */ -}}
  {{- $_sources := fromYamlArray (include "base.get" (list . "sources")) }}
  {{- if eq (include "base.isFromYamlArrayError" $_sources) "true" }}
    {{- fail "[definitions.projectedVolumeSource] sources: must be array type" }}
  {{- end }}
  {{- $sources := list }}
  {{- range $_source := $_sources }}
    {{- if not (kindIs "map" $_source) }}
      {{- fail (printf "[definitions.projectedVolumeSource] sources: each item must be object type, got '%s'" (kindOf $_source)) }}
    {{- end }}
    {{- $_rendered := fromYaml (include "definitions.volumeProjection" $_source) }}
    {{- if eq (include "base.isFromYamlError" $_rendered) "true" }}
      {{- fail "[definitions.projectedVolumeSource] sources: definitions.volumeProjection rendered invalid YAML" }}
    {{- end }}
    {{- if $_rendered }}
      {{- $sources = mustAppend $sources $_rendered }}
    {{- end }}
  {{- end }}
  {{- $sources = mustUniq $sources }}
  {{- if $sources }}
    {{- include "base.field" (list "sources" $sources "base.slice") }}
  {{- end }}
{{- end }}
