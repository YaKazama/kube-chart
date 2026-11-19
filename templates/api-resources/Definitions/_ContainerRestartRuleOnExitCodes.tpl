{{- /*
  渲染 Kubernetes ContainerRestartRuleOnExitCodes 字段片段。

  行为 (按 K8s API 规范字段顺序):
    - operator (string, 必填): 大小写不敏感匹配 In、NotIn，归一化后以官方值带引号输出。
    - values   (integer array, 必填): 1 - 255 个整数，显式 0 保留；非整数或数量越界时中断。

  边界:
    - 只输出当前层字段，不输出 exitCodes 父键、apiVersion 或 kind。
    - 上下文按 map 契约读取 operator 与 values，不支持 string 简写，不提供默认值。
    - operatorAlias、valuesAlias 不识别；operator 缺失、为 null、为空或不是 string 时中断，非法枚举由 base.field 中断。
    - values 缺失、为 null、不是 array 或为空数组时中断；int、int64 原值保留，等于整数的 float64 收敛为整数，其他类型及非整数数值中断。
    - values 元素数量超过 255 时中断。
    - 本模板主动产生的失败消息使用 [definitions.containerRestartRuleOnExitCodes] 前缀；委托 base.get、base.string.normalize、base.field、base.slice 时保留其自身前缀。

  入参: 键为 operator、values 的 map。
    - operator (string, 必填)        大小写不敏感的 In 或 NotIn
    - values   (integer array, 必填) 1 - 255 个退出码

  返回值: 可嵌入 ContainerRestartRule 的 exitCodes YAML 字段片段；非法入参中断渲染。

  示例:
    {{- include "definitions.containerRestartRuleOnExitCodes" (dict "operator" "in" "values" (list 0 137)) }}
      // operator: "In"
      // values:
      //   - 0
      //   - 137
*/ -}}
{{- define "definitions.containerRestartRuleOnExitCodes" -}}
  {{- /* operator（string, 必填）: base.get 关闭别名识别取值，base.string.normalize 按 YAML 标量解码并执行 string 类型门禁；空值中断，大小写归一化后由 base.field 以官方枚举列表校验并带引号输出。 */ -}}
  {{- $operator := include "base.string.normalize" (include "base.get" (list . "operator" "" "" false false)) }}
  {{- if eq $operator "" }}
    {{- fail "[definitions.containerRestartRuleOnExitCodes] operator: required field is missing or empty" }}
  {{- end }}
  {{- $operator = get (dict "in" "In" "notin" "NotIn") (lower $operator) }}
  {{- include "base.field" (list "operator" $operator "quote" (list "In" "NotIn")) }}

  {{- /* values（integer array, 必填）: base.get 关闭别名识别取值，fromYamlArray 恢复后先排除解析错误；空数组或元素超过 255 个时中断，元素逐项校验 int、int64 或整值 float64 并保留显式 0，最终由 base.slice 输出。 */ -}}
  {{- $_valuesParsed := include "base.get" (list . "values" "" "" false false) | fromYamlArray }}
  {{- if eq (include "base.isFromYamlArrayError" $_valuesParsed) "true" }}
    {{- fail "[definitions.containerRestartRuleOnExitCodes] values: must be integer array type" }}
  {{- end }}
  {{- if or (eq (len $_valuesParsed) 0) (gt (len $_valuesParsed) 255) }}
    {{- fail (printf "[definitions.containerRestartRuleOnExitCodes] values: must contain 1-255 items, got '%d'" (len $_valuesParsed)) }}
  {{- end }}

  {{- $values := list }}
  {{- range $_value := $_valuesParsed }}
    {{- if or (kindIs "int" $_value) (kindIs "int64" $_value) }}
      {{- $values = mustAppend $values $_value }}
    {{- else if and (kindIs "float64" $_value) (eq $_value (floor $_value)) }}
      {{- $values = mustAppend $values (int64 $_value) }}

    {{- else }}
      {{- fail (printf "[definitions.containerRestartRuleOnExitCodes] values: item '%v' must be an integer" $_value) }}
    {{- end }}
  {{- end }}
  {{- include "base.field" (list "values" $values "base.slice") }}
{{- end }}
