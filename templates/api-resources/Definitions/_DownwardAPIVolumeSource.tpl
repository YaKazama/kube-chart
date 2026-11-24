{{- /*
  渲染 Kubernetes DownwardAPIVolumeSource 字段片段。

  行为 (按 K8s API 规范字段顺序):
    - defaultMode (integer, 可选): 接受八进制 0000-0777 或十进制 0-511 的数值/字符串，归一化为十进制 int 输出；空值省略。
    - items       (DownwardAPIVolumeFile array, 可选): 接受 map 数组、string 数组或两者混合；空白 string 跳过；string item 按 `<path> [mode] field <fieldPath> [apiVersion]` 或 `<path> [mode] resource <resource> [containerName] [divisor]` 过滤，组装为 `{path, [mode], fieldRef: <string>}` 或 `{path, [mode], resourceFieldRef: <string>}`；map 元素原样传递；每个元素委托 definitions.downwardAPIVolumeFile；空数组或全空白省略。

  边界:
    - 只读取 defaultMode 与 items，其他字段静默忽略；按 API 顺序输出已生效字段。
    - string item 先按 field 形态匹配，未匹配再按 resource 形态匹配，都不匹配时中断；path、mode 与 *Ref 串只取自捕获段，不归一化 path、不做 YAML 标量解码或剥离引号。
    - fieldRef/resourceFieldRef 保持 string，其字段拆分、内部字段校验、互斥判定与孙模板委托由 definitions.downwardAPIVolumeFile 负责；本模板不构造这两个 map。
    - 原生 map item 原样直传，不清洗、改写或调用孙模板；子模板输出为空时跳过该元素，非法 YAML 或非 map 时中断。

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
  {{- $_ := "" }}

  {{- /* defaultMode（integer, 可选）: 剥离 YAML 引号后归一化为十进制 int，显式 0 有效。 */ -}}
  {{- $_defaultModeRaw := include "base.get" (list . "defaultMode") | trim }}
  {{- if $_defaultModeRaw }}
    {{- $defaultMode := mustRegexReplaceAll $const.SYS.YAML_QUOTED $_defaultModeRaw "$1" | trim }}
    {{- if $defaultMode }}
      {{- include "base.field" (list "defaultMode" (include "base.fileMode" $defaultMode) "base.int") }}
    {{- end }}
  {{- end }}

  {{- /* items（DownwardAPIVolumeFile array, 可选）: string 按 field/resource 形态过滤、map 原样传递；空数组或全空白省略。 */ -}}
  {{- $_items := fromYamlArray (include "base.get" (list . "items")) }}
  {{- if eq (include "base.isFromYamlArrayError" $_items) "true" }}
    {{- fail "[definitions.downwardAPIVolumeSource] items: must be array type" }}
  {{- end }}
  {{- $items := list }}
  {{- range $_element := $_items }}
    {{- $itemContext := $_element }}
    {{- if kindIs "string" $_element }}
      {{- $_text := trim $_element }}
      {{- if not $_text }}
        {{- continue }}
      {{- end }}

      {{- /* 形态判定: field 优先，未匹配时再按 resource；都不匹配时中断。 */ -}}
      {{- $_isField := mustRegexMatch $const.K8S.VOLUME.DOWNWARD_API_FIELD_ITEM $_text }}
      {{- $_pattern := $const.K8S.VOLUME.DOWNWARD_API_FIELD_ITEM }}
      {{- if not $_isField }}
        {{- $_pattern = $const.K8S.VOLUME.DOWNWARD_API_RESOURCE_ITEM }}
        {{- if not (mustRegexMatch $_pattern $_text) }}
          {{- fail (printf "[definitions.downwardAPIVolumeSource] items: '%s' does not match '<path> [mode] field <fieldPath> [apiVersion]' or '<path> [mode] resource <resource> [containerName] [divisor]'" $_text) }}
        {{- end }}
      {{- end }}

      {{- /* 上下文构造: path 必填，mode 可选；*Ref 串由捕获段以单个空格连接，保持 string 交给子模板。 */ -}}
      {{- $itemContext = dict "path" (mustRegexReplaceAll $_pattern $_text "$1" | trim) }}
      {{- $_mode := mustRegexReplaceAll $_pattern $_text "$2" | trim }}
      {{- if $_mode }}
        {{- $_ = set $itemContext "mode" $_mode }}
      {{- end }}
      {{- $_refParts := list (mustRegexReplaceAll $_pattern $_text "$3" | trim) (mustRegexReplaceAll $_pattern $_text "$4" | trim) }}
      {{- if not $_isField }}
        {{- $_refParts = mustAppend $_refParts (mustRegexReplaceAll $_pattern $_text "$5" | trim) }}
      {{- end }}
      {{- $_ = set $itemContext (ternary "fieldRef" "resourceFieldRef" $_isField) (join " " (mustWithout $_refParts "")) }}
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
