{{- /*
  渲染 Kubernetes DownwardAPIVolumeFile 字段片段。

  行为 (按 K8s API 规范字段顺序):
    - fieldRef (ObjectFieldSelector, 与 resourceFieldRef 互斥): 值为 map 时原样透传；为 string 时按 fieldPath、apiVersion 位次组装；委托 definitions.objectFieldSelector。
    - mode (integer, 可选): 接受八进制 0000-0777 或十进制 0-511 的数值/字符串，归一化为十进制 int 输出；空值省略。
    - path (string, 必填): 解码后 trim 判空，归一化为相对路径并拒绝绝对路径；归一化结果为 `..` 或以 `../` 开头时中断；以带引号标量输出。
    - resourceFieldRef (ResourceFieldSelector, 与 fieldRef 互斥): 值为 map 时原样透传；为 string 时按 resource、containerName、divisor 位次组装；委托 definitions.resourceFieldSelector。

  边界:
    - 只输出 fieldRef、mode、path、resourceFieldRef，其他字段静默忽略；按上述官方顺序输出已生效字段。
    - fieldRef 与 resourceFieldRef 必须恰好存在一个且值非空；两个并存、都缺失或唯一存在的值为空 string/空 map 时中断。
    - 引用值为 map 时不校验、补全或改写；为 string 时以空格切分，位次与 DOWNWARD_API_FIELD_ITEM、DOWNWARD_API_RESOURCE_ITEM 的捕获顺序一致，超出位次的段忽略，必需段缺失时中断。
    - 引用值既不是 map 也不是 string 时中断，失败消息包含字段名。
    - path 的 `.` / `..` 段归一化由 base.path 的 rel 模式完成；前导 `..` 由本模板补足拒绝。
    - mode 的归一化由 base.fileMode 完成，与 defaultMode 语义一致。

  入参: map，形如 `{path: "meta/name", fieldRef: "metadata.name v1", mode: "0400"}`。

  返回值: 可嵌入 DownwardAPIVolumeSource.items 数组元素的 YAML 字段片段。

  示例:
    {{- include "definitions.downwardAPIVolumeFile" (dict "path" "meta/name" "fieldRef" (dict "fieldPath" "metadata.name")) }}
      // fieldRef:
      //   fieldPath: "metadata.name"
      // path: "meta/name"
    {{- include "definitions.downwardAPIVolumeFile" (dict "path" "cpu" "resourceFieldRef" "limits.cpu app 1m" "mode" "0400") }}
      // mode: 256
      // path: "cpu"
      // resourceFieldRef:
      //   containerName: "app"
      //   divisor: "1m"
      //   resource: "limits.cpu"
*/ -}}
{{- define "definitions.downwardAPIVolumeFile" -}}
  {{- $const := include "base.env" "" | fromYaml }}

  {{- /* fieldRef 与 resourceFieldRef（互斥关联字段，必须恰好出现一个）: 先完成互斥校验，再由同一布尔量派生字段名与子模板名。 */ -}}
  {{- $hasFieldRef := hasKey . "fieldRef" }}
  {{- $hasResourceFieldRef := hasKey . "resourceFieldRef" }}
  {{- if eq $hasFieldRef $hasResourceFieldRef }}
    {{- $_present := list }}
    {{- if $hasFieldRef }}
      {{- $_present = mustAppend $_present "fieldRef" }}
    {{- end }}
    {{- if $hasResourceFieldRef }}
      {{- $_present = mustAppend $_present "resourceFieldRef" }}
    {{- end }}
    {{- fail (printf "[definitions.downwardAPIVolumeFile] fields: exactly one of 'fieldRef' or 'resourceFieldRef' is required, got '%v'" (join ", " $_present)) }}
  {{- end }}
  {{- $refKey := ternary "fieldRef" "resourceFieldRef" $hasFieldRef }}
  {{- $refDefine := ternary "definitions.objectFieldSelector" "definitions.resourceFieldSelector" $hasFieldRef }}
  {{- $_refRaw := get . $refKey }}

  {{- /* 引用值归一: string 按位次组装；map 原样透传；空值与其余类型中断。 */ -}}
  {{- $selector := dict }}
  {{- if kindIs "string" $_refRaw }}
    {{- $_parts := mustWithout (mustRegexSplit $const.SPLIT.SPACE (trim $_refRaw) -1) "" }}
    {{- if not $_parts }}
      {{- fail (printf "[definitions.downwardAPIVolumeFile] %s: value must not be empty" $refKey) }}
    {{- end }}
    {{- $_ := set $selector (ternary "fieldPath" "resource" $hasFieldRef) (index $_parts 0) }}
    {{- if ge (len $_parts) 2 }}
      {{- $_ := set $selector (ternary "apiVersion" "containerName" $hasFieldRef) (index $_parts 1) }}
    {{- end }}
    {{- if and (not $hasFieldRef) (ge (len $_parts) 3) }}
      {{- $_ := set $selector "divisor" (index $_parts 2) }}
    {{- end }}

  {{- else if kindIs "map" $_refRaw }}
    {{- if not $_refRaw }}
      {{- fail (printf "[definitions.downwardAPIVolumeFile] %s: value must not be empty" $refKey) }}
    {{- end }}
    {{- $selector = $_refRaw }}

  {{- else }}
    {{- fail (printf "[definitions.downwardAPIVolumeFile] %s: must be object or string, got '%s'" $refKey (kindOf $_refRaw)) }}
  {{- end }}

  {{- /* 委托引用子模板: 结果非法 YAML 时中断，非空时以 base.field 与 base.map 渲染为片段。 */ -}}
  {{- $_selectorRendered := include $refDefine $selector | fromYaml }}
  {{- if eq (include "base.isFromYamlError" $_selectorRendered) "true" }}
    {{- fail (printf "[definitions.downwardAPIVolumeFile] %s: invalid YAML output from %s" $refKey $refDefine) }}
  {{- end }}
  {{- $refFragment := include "base.field" (list $refKey $_selectorRendered "base.map") }}

  {{- /* mode（integer, 可选）: 剥离 YAML 引号后归一化为十进制 int，显式 0 有效。 */ -}}
  {{- $modeFragment := "" }}
  {{- $_modeRaw := include "base.get" (list . "mode") | trim }}
  {{- if $_modeRaw }}
    {{- $mode := mustRegexReplaceAll $const.SYS.YAML_QUOTED $_modeRaw "$1" | trim }}
    {{- if $mode }}
      {{- $modeFragment = include "base.field" (list "mode" (include "base.fileMode" $mode) "base.int") }}
    {{- end }}
  {{- end }}

  {{- /* path（string, 必填）: 解码后 trim 判空，经 rel 模式归一化并拒绝前导 `..`，再以带引号标量输出。 */ -}}
  {{- $path := include "base.string.normalize" (include "base.get" (list . "path")) | trim }}
  {{- if not $path }}
    {{- fail "[definitions.downwardAPIVolumeFile] path: required field is missing or empty" }}
  {{- end }}
  {{- $path = include "base.path" (list $path "rel") }}
  {{- if or (eq $path "..") (hasPrefix "../" $path) }}
    {{- fail (printf "[definitions.downwardAPIVolumeFile] path: '%s' must not be '..' or start with '../'" $path) }}
  {{- end }}
  {{- $pathFragment := include "base.field" (list "path" $path "quote") }}

  {{- /* 按官方字段顺序输出: fieldRef 在 mode、path 之前，resourceFieldRef 在最后。 */ -}}
  {{- if $hasFieldRef }}
    {{- $refFragment }}{{ $modeFragment }}{{ $pathFragment }}
  {{- else }}
    {{- $modeFragment }}{{ $pathFragment }}{{ $refFragment }}
  {{- end }}
{{- end }}
