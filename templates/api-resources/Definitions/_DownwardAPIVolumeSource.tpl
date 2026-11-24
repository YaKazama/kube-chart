{{- /*
  渲染 Kubernetes DownwardAPIVolumeSource 字段片段。

  行为 (按 K8s API 规范字段顺序):
    - defaultMode (integer, 可选): 接受八进制 0000-0777 或十进制 0-511 的数值/字符串，归一化为十进制 int 输出；空值省略。
    - items       (DownwardAPIVolumeFile array, 可选): 接受 map 数组、string 数组或两者混合；空白 string 跳过，非空白 string 以 `dict "item"` 原样包装，map 元素原样传递；每个元素委托 definitions.downwardAPIVolumeFile；空数组或全空白省略。

  边界:
    - 只读取 defaultMode 与 items，其他字段静默忽略；按 API 顺序输出已生效字段。
    - 本模板不解析 string item 段位、不构造 item map、不归一化 path；item 段位解析、path/fieldRef/resourceFieldRef/mode 构造与内部字段校验由 definitions.downwardAPIVolumeFile 负责。
    - 每个 item 的原始 string 或 map 作为独立上下文传给子模板；子模板输出为空时跳过该元素，非法 YAML 或非 map 时中断。

  入参: map，形如 `{defaultMode: "0644", items: ["meta 0400 field metadata.name"]}`。

  返回值: 可嵌入 Volume.downwardAPI 位置的 YAML 字段片段。

  示例:
    {{- include "definitions.downwardAPIVolumeSource" (dict "defaultMode" "0644" "items" (list "meta field metadata.name")) }}
      // defaultMode: 420
      // items:
      //   - ...
*/ -}}
{{- define "definitions.downwardAPIVolumeSource" -}}
  {{- $const := include "base.env" "" | fromYaml }}

  {{- /* defaultMode（integer, 可选）: 剥离 YAML 引号后归一化为十进制 int，显式 0 有效。 */ -}}
  {{- $_defaultModeRaw := include "base.get" (list . "defaultMode") | trim }}
  {{- if $_defaultModeRaw }}
    {{- $defaultMode := mustRegexReplaceAll $const.SYS.YAML_QUOTED $_defaultModeRaw "$1" | trim }}
    {{- if $defaultMode }}
      {{- include "base.field" (list "defaultMode" (include "base.fileMode" $defaultMode) "base.int") }}
    {{- end }}
  {{- end }}

  {{- /* items（DownwardAPIVolumeFile array, 可选）: string 原样包装、map 原样传递；空数组或全空白省略。 */ -}}
  {{- $_items := fromYamlArray (include "base.get" (list . "items")) }}
  {{- if eq (include "base.isFromYamlArrayError" $_items) "true" }}
    {{- fail "[definitions.downwardAPIVolumeSource] items: must be array type" }}
  {{- end }}
  {{- $items := list }}
  {{- range $_element := $_items }}
    {{- $itemContext := $_element }}
    {{- if kindIs "string" $_element }}
      {{- if not (trim $_element) }}
        {{- continue }}
      {{- end }}
      {{- $itemContext = dict "item" $_element }}
    {{- else if not (kindIs "map" $_element) }}
      {{- fail (printf "[definitions.downwardAPIVolumeSource] items: each item must be object or string type, got '%s'" (kindOf $_element)) }}
    {{- end }}

    {{- /* 委托 definitions.downwardAPIVolumeFile：空输出跳过，非法 YAML 或非 map 中断。 */ -}}
    {{- $_parsed := fromYaml (include "definitions.downwardAPIVolumeFile" $itemContext) }}
    {{- if eq (include "base.isFromYamlError" $_parsed) "true" }}
      {{- fail "[definitions.downwardAPIVolumeSource] items: definitions.downwardAPIVolumeFile rendered invalid YAML or non-map content" }}
    {{- end }}
    {{- if $_parsed }}
      {{- $items = mustAppend $items $_parsed }}
    {{- end }}
  {{- end }}
  {{- if $items }}
    {{- include "base.field" (list "items" $items "base.slice") }}
  {{- end }}
{{- end }}
