{{- /*
  渲染 Kubernetes NodeSelectorRequirement 字段片段。

  行为 (按 K8s API 规范字段顺序):
    - key (string, 必填): 经 base.get 必填模式取值（内含别名识别与必填校验），确认 string 类型后剥离 YAML 外层引号；类型不符或为空时中断。
    - operator (string, 必填): 与 key 同链路取值与类型校验，六个枚举由 base.field 的允许值列表校验，大小写敏感。
    - values (string array, 可选): 经 base.get 取值、fromYamlArray 恢复与错误保护后统一转为 string；非 array 中断。In、NotIn、Gt、Lt 分支内校验并输出该字段，Exists、DoesNotExist 分支只校验其为空，不进入渲染路径。

  边界:
    - 入参是父级已清洗的扁平 map，不接受 string 简写，不做条目去重。
    - keyAlias、operatorAlias、valuesAlias 由 base.get 隐式识别，本层不维护别名映射。
    - 空 map 直接返回空字符串，不触发 key、operator 的必填校验。
    - 不拆分、去空、去重或规范化 values，不校验标签键语法，不输出 status。
    - values 的输出由 operator 分支显式决定，不以 values 非空作为输出开关。
    - 本模板主动产生的失败消息使用 [definitions.nodeSelectorRequirement] 前缀并带字段名；委托 base.get、base.field 时保留其自身前缀。

  入参: 上下文 map，可包含以下字段:
    - key           (string, 必填)       节点标签键或字段键
    - operator      (string, 必填)       DoesNotExist、Exists、Gt、In、Lt、NotIn，大小写敏感
    - values        (string array, 可选) 与该 operator 相关的取值，元素非 string 时转为 string
    - keyAlias      (string, 可选)       内置别名，非空时优先于 key
    - operatorAlias (string, 可选)       内置别名，非空时优先于 operator
    - valuesAlias   (string array, 可选) 内置别名，非空时优先于 values

  返回值: 可嵌入 NodeSelectorTerm 的 matchExpressions、matchFields 单项 YAML 字段片段；空 map 返回空字符串，非法入参中断渲染。

  示例:
    {{- include "definitions.nodeSelectorRequirement" (dict "key" "kubernetes.io/os" "operator" "In" "values" (list "linux")) }}
*/ -}}
{{- define "definitions.nodeSelectorRequirement" -}}
  {{- if . }}
    {{- $const := include "base.env" "" | fromYaml }}

    {{- /* key、operator（string, 必填）: base.get 承担取值、别名识别与必填校验，剥离 YAML 外层引号并 trim 后暂存；类型不符或归一化后为空时中断。 */ -}}
    {{- $scalars := dict }}
    {{- range $_name := list "key" "operator" }}
      {{- $_raw := include "base.get" (list $ $_name "" "" true) | trim }}
      {{- if not (kindIs "string" (fromYaml (printf "v: %s" $_raw)).v) }}
        {{- fail (printf "[definitions.nodeSelectorRequirement] %s: must be string type, got '%s'" $_name $_raw) }}
      {{- end }}
      {{- $_value := mustRegexReplaceAll $const.SYS.YAML_QUOTED $_raw "$1" | trim }}
      {{- if eq $_value "" }}
        {{- fail (printf "[definitions.nodeSelectorRequirement] %s: required field is missing or empty" $_name) }}
      {{- end }}
      {{- $_ := set $scalars $_name $_value }}
    {{- end }}

    {{- /* key（string, 必填）: 以 base.rawString 原样输出，避免 base.string 的零折叠改写键内容。 */ -}}
    {{- include "base.field" (list "key" (get $scalars "key") "base.rawString") }}

    {{- /* operator（string, 必填）: 六个枚举由 base.field 的允许值列表校验，大小写敏感。 */ -}}
    {{- $operator := get $scalars "operator" }}
    {{- include "base.field" (list "operator" $operator "" (list "DoesNotExist" "Exists" "Gt" "In" "Lt" "NotIn")) }}

    {{- /* values（string array, 可选）: 非 array 中断，元素统一转为 string；输出由 operator 分支决定，In、NotIn 必须非空，Gt、Lt 必须恰好一个整数，Exists、DoesNotExist 必须为空且不渲染。 */ -}}
    {{- $_values := fromYamlArray (include "base.get" (list . "values")) }}
    {{- if eq (include "base.isFromYamlArrayError" $_values) "true" }}
      {{- fail "[definitions.nodeSelectorRequirement] values: must be array type" }}
    {{- end }}
    {{- $values := toStrings $_values }}

    {{- if or (eq $operator "In") (eq $operator "NotIn") }}
      {{- if not $values }}
        {{- fail (printf "[definitions.nodeSelectorRequirement] values: required for %s" $operator) }}
      {{- end }}
      {{- include "base.field" (list "values" $values "base.slice") }}

    {{- else if or (eq $operator "Gt") (eq $operator "Lt") }}
      {{- if ne (len $values) 1 }}
        {{- fail (printf "[definitions.nodeSelectorRequirement] values: %s requires exactly one value" $operator) }}
      {{- end }}
      {{- if not (mustRegexMatch $const.TYPES.INT (first $values)) }}
        {{- fail (printf "[definitions.nodeSelectorRequirement] values: %s requires an integer value" $operator) }}
      {{- end }}
      {{- include "base.field" (list "values" $values "base.slice") }}

    {{- else if $values }}
      {{- fail (printf "[definitions.nodeSelectorRequirement] values: must be empty for %s" $operator) }}
    {{- end }}
  {{- end }}
{{- end }}
