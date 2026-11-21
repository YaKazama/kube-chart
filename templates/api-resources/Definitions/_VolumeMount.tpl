{{- /*
  渲染 Kubernetes VolumeMount 字段片段。

  行为 (按 K8s API 规范字段顺序):
    - mountPath          (string, 必填): 非空且不得包含 ':'，以带引号标量输出。
    - mountPropagation   (string, 可选): 按 Bidirectional、HostToContainer、None 枚举校验后以带引号标量输出。
    - name               (string, 必填): 规范化为小写后按 RFC1123 Label 校验，以带引号标量输出。
    - readOnly           (boolean, 可选): 仅接受 true/false；未提供时省略字段，显式 false 也输出。
    - recursiveReadOnly  (string, 可选): 按 Disabled、IfPossible、Enabled 枚举校验；非空时要求 readOnly=true；为 IfPossible 或 Enabled 时 mountPropagation 必须为 None 或未提供。
    - subPath            (string, 可选): 非空时以带引号标量输出。
    - subPathExpr        (string, 可选): 非空时以带引号标量输出；与 subPath 互斥。

  边界:
    - 只输出当前层字段，不输出 volumeMounts 父键、apiVersion 或 kind。
    - 上下文为 VolumeMount map 或字符串简写；其他类型中断。
    - map 只读取 name、mountPath、readOnly、recursiveReadOnly、mountPropagation、subPath、subPathExpr，未声明的键静默忽略；base.get 默认开启别名，因此各字段同级 <字段>Alias 隐式生效。
    - 字符串格式为 <name> <mountPath> [subPath|subPathExpr] [readOnly] [recursiveReadOnly] [mountPropagation]，字段间分隔符为一个或多个空白或逗号，整段匹配不区分大小写。
    - 字符串第 3 段按完整 $(VAR_NAME) 形式匹配：命中时作为 subPathExpr，否则作为 subPath；未提供的尾部可选段为空并省略，不能跳过前面的可选段。
    - 捕获后的 readOnly、recursiveReadOnly 与 mountPropagation 仍按大小写敏感校验，仅接受规范拼写；TRUE、enabled 等变体中断。
    - 字符串字段缺失、为 null、为空字符串或只含空白时按未提供处理；name 与 mountPath 必填缺失时中断；字符串字段不是 string 时由 base.string.normalize 中断。
    - name 在 RFC1123 校验与输出前规范化为小写。
    - subPath 与 subPathExpr 同时非空时中断；readOnly 不为 true 且 recursiveReadOnly 非空时中断。
    - 枚举比较大小写敏感，未命中时由 base.field 中断并给出合法范围。

  入参: VolumeMount 字段 map，或上述格式的 string。

  返回值: 可嵌入 containers[].volumeMounts 元素的 VolumeMount YAML 字段片段。

  示例:
    {{- include "definitions.volumeMount" (dict "name" "Data" "mountPath" "/data") }}
      // mountPath: "/data"
      // name: "data"
    {{- include "definitions.volumeMount" "data, /data, cache-v1, true, IfPossible, None" }}
      // mountPath: "/data"
      // mountPropagation: "None"
      // name: "data"
      // readOnly: true
      // recursiveReadOnly: "IfPossible"
      // subPath: "cache-v1"
*/ -}}
{{- define "definitions.volumeMount" -}}
  {{- $const := include "base.env" "" | fromYaml }}

  {{- $name := "" }}
  {{- $mountPath := "" }}
  {{- $readOnly := "" }}
  {{- $recursiveReadOnly := "" }}
  {{- $mountPropagation := "" }}
  {{- $subPath := "" }}
  {{- $subPathExpr := "" }}
  {{- $_readOnlyRaw := "" }}
  {{- $_subPathLike := "" }}

  {{- /* 上下文分派: string 走位置解析，map 逐字段取值，归一为同一组字段后共用校验与渲染。 */ -}}
  {{- $_contextKind := kindOf . }}

  {{- if eq $_contextKind "string" }}
    {{- $_pattern := $const.K8S.VOLUME_MOUNT }}

    {{- /* 快速失败: 整段匹配成功后才能按捕获组位置提取。 */ -}}
    {{- if not (mustRegexMatch $_pattern .) }}
      {{- fail (printf "[definitions.volumeMount] input: '%s' does not match '<name> <mountPath> [subPath|subPathExpr] [readOnly] [recursiveReadOnly] [mountPropagation]'" .) }}
    {{- end }}
    {{- $name = mustRegexReplaceAll $_pattern . "$1" | trim }}
    {{- $mountPath = mustRegexReplaceAll $_pattern . "$2" | trim }}
    {{- $_subPathLike = mustRegexReplaceAll $_pattern . "$3" | trim }}
    {{- $_readOnlyRaw = mustRegexReplaceAll $_pattern . "$4" | trim }}
    {{- $recursiveReadOnly = mustRegexReplaceAll $_pattern . "$5" | trim }}
    {{- $mountPropagation = mustRegexReplaceAll $_pattern . "$6" | trim }}

    {{- if $_subPathLike }}
      {{- if mustRegexMatch $const.K8S.VOLUME_MOUNT_SUB_PATH_LIKE $_subPathLike }}
        {{- $subPathExpr = $_subPathLike }}
      {{- else }}
        {{- $subPath = $_subPathLike }}
      {{- end }}
    {{- end }}

  {{- else if eq $_contextKind "map" }}
    {{- $mountPath = include "base.string.normalize" (include "base.get" (list . "mountPath")) | trim }}
    {{- $mountPropagation = include "base.string.normalize" (include "base.get" (list . "mountPropagation")) | trim }}
    {{- $name = include "base.string.normalize" (include "base.get" (list . "name")) | trim }}
    {{- $_readOnlyRaw = include "base.get" (list . "readOnly") | trim }}
    {{- $recursiveReadOnly = include "base.string.normalize" (include "base.get" (list . "recursiveReadOnly")) | trim }}
    {{- $subPath = include "base.string.normalize" (include "base.get" (list . "subPath")) | trim }}
    {{- $subPathExpr = include "base.string.normalize" (include "base.get" (list . "subPathExpr")) | trim }}

  {{- else }}
    {{- fail (printf "[definitions.volumeMount] input: must be object or string type, got '%s'" $_contextKind) }}
  {{- end }}

  {{- $name = lower $name }}

  {{- /* mountPath（string, 必填）: 非空且不得包含 ':'。 */ -}}
  {{- if not $mountPath }}
    {{- fail "[definitions.volumeMount] mountPath: required field is missing or empty" }}
  {{- end }}
  {{- if contains ":" $mountPath }}
    {{- fail "[definitions.volumeMount] mountPath: must not contain ':'" }}
  {{- end }}

  {{- /* name（string, 必填）: 小写规范化后按 RFC1123 Label 校验。 */ -}}
  {{- if not $name }}
    {{- fail "[definitions.volumeMount] name: required field is missing or empty" }}
  {{- end }}
  {{- $name = include "base.rfc" (list $name "1123") }}

  {{- /* readOnly（boolean, 可选）: 仅接受 true/false。 */ -}}
  {{- if $_readOnlyRaw }}
    {{- $readOnly = include "base.bool" (mustRegexReplaceAll $const.SYS.YAML_QUOTED $_readOnlyRaw "$1" | trim) }}
  {{- end }}

  {{- /* recursiveReadOnly（string, 可选）: 要求 readOnly=true，并限制 mountPropagation。 */ -}}
  {{- if and $recursiveReadOnly (ne $readOnly "true") }}
    {{- fail "[definitions.volumeMount] recursiveReadOnly: requires readOnly=true" }}
  {{- end }}
  {{- if and (or (eq $recursiveReadOnly "IfPossible") (eq $recursiveReadOnly "Enabled")) $mountPropagation (ne $mountPropagation "None") }}
    {{- fail "[definitions.volumeMount] mountPropagation: must be None or unset when recursiveReadOnly is IfPossible or Enabled" }}
  {{- end }}

  {{- /* subPath 与 subPathExpr（string, 可选）: 互斥。 */ -}}
  {{- if and $subPath $subPathExpr }}
    {{- fail "[definitions.volumeMount] subPath and subPathExpr: mutually exclusive" }}
  {{- end }}

  {{- /* mountPath（string, 必填）: 以带引号标量输出。 */ -}}
  {{- include "base.field" (list "mountPath" $mountPath "quote") }}

  {{- /* mountPropagation（string, 可选）: 枚举校验后以带引号标量输出。 */ -}}
  {{- if $mountPropagation }}
    {{- include "base.field" (list "mountPropagation" $mountPropagation "quote" (list "Bidirectional" "HostToContainer" "None")) }}
  {{- end }}

  {{- /* name（string, 必填）: 以带引号标量输出。 */ -}}
  {{- include "base.field" (list "name" $name "quote") }}

  {{- /* readOnly（boolean, 可选）: 按布尔输出，显式 false 也输出。 */ -}}
  {{- if $readOnly }}
    {{- include "base.field" (list "readOnly" $readOnly "base.bool") }}
  {{- end }}

  {{- /* recursiveReadOnly（string, 可选）: 枚举校验后以带引号标量输出。 */ -}}
  {{- if $recursiveReadOnly }}
    {{- include "base.field" (list "recursiveReadOnly" $recursiveReadOnly "quote" (list "Disabled" "IfPossible" "Enabled")) }}
  {{- end }}

  {{- /* subPath（string, 可选）: 非空时以带引号标量输出。 */ -}}
  {{- if $subPath }}
    {{- include "base.field" (list "subPath" $subPath "quote") }}
  {{- end }}

  {{- /* subPathExpr（string, 可选）: 非空时以带引号标量输出。 */ -}}
  {{- if $subPathExpr }}
    {{- include "base.field" (list "subPathExpr" $subPathExpr "quote") }}
  {{- end }}
{{- end }}
