{{- /*
  渲染 Kubernetes ContainerRestartRule 字段片段。

  行为 (按 K8s API 规范字段顺序):
    - action    (string, 必填): 唯一合法取值为 restart（大小写不敏感），归一化后以 Restart 输出。
    - exitCodes (ContainerRestartRuleOnExitCodes, 必填): 非空对象时原样委托 definitions.containerRestartRuleOnExitCodes。

  边界:
    - 只输出当前层字段，不输出 restartPolicyRules 父键、apiVersion 或 kind。
    - 上下文为 string 或 map；其他类型中断。
    - string 形如 <action> <operator> (<int>, <int>, ...)，段间分隔符为空白或逗号；action 大小写不敏感，operator 作为非空 token 按原样传递且枚举由子模板校验；括号内 values 以逗号拆分并逐项转为整数，显式 0 保留。
    - string 清洗后传给子模板的上下文只含 operator 与 values，不含 action。
    - map 只读取 action 与 exitCodes，其他键不参与校验与输出，也不导致中断。
    - action 缺失、为 null、为空或不是 restart 时中断；exitCodes 缺失、为 null、为空对象或非对象时中断。
    - 不校验 exitCodes.values 的元素数量上限，也不校验 exitCodes.operator 的枚举取值与大小写；两者由子模板负责。
    - base.get 默认开启别名识别，因此 map 同级 actionAlias、exitCodesAlias 隐式生效。
    - 子模板返回非法 YAML 或空内容时中断。

  入参: 单个 string 标量，或键为 action、exitCodes 的 map。

  返回值: 可嵌入 containers[].restartPolicyRules 元素的 ContainerRestartRule YAML 字段片段。

  示例:
    {{- include "definitions.containerRestartRule" "restart in (0, 1)" }}
      // action: "Restart"
      // exitCodes:
      //   operator: "in"
      //   values: [0, 1]
    {{- include "definitions.containerRestartRule" (dict "action" "RESTART" "exitCodes" (dict "operator" "notin" "values" (list 137))) }}
*/ -}}
{{- define "definitions.containerRestartRule" -}}
  {{- $const := include "base.env" "" | fromYaml }}

  {{- /* 上下文分派: string 按简写解析并清洗 exitCodes，map 逐字段取值，归一为 action 与 exitCodes 后共用渲染。 */ -}}
  {{- $action := "" }}
  {{- $_exitCodes := dict }}
  {{- $_contextKind := kindOf . }}

  {{- if eq $_contextKind "string" }}
    {{- $_pattern := $const.K8S.CONTAINER_RESTART_RULE }}

    {{- /* 快速失败: 整体匹配成功后才能按捕获组位置提取 */ -}}
    {{- if not (mustRegexMatch $_pattern .) }}
      {{- fail (printf "[definitions.containerRestartRule] input: '%s' does not match '<action> <operator> (<int>, <int>, ...)'" .) }}
    {{- end }}
    {{- $action = "Restart" }}
    {{- $_operator := mustRegexReplaceAll $_pattern . "$2" }}
    {{- $_valuesRaw := mustRegexReplaceAll $_pattern . "$3" | trim }}

    {{- $values := list }}
    {{- range $_item := mustRegexSplit $const.SPLIT.COMMA $_valuesRaw -1 }}
      {{- $_value := trim $_item }}
      {{- if not (mustRegexMatch $const.TYPES.INT $_value) }}
        {{- fail (printf "[definitions.containerRestartRule] input: values item '%s' is not an integer" $_value) }}
      {{- end }}
      {{- $values = mustAppend $values (atoi $_value) }}
    {{- end }}

    {{- $_exitCodes = dict "operator" $_operator "values" $values }}

  {{- else if eq $_contextKind "map" }}
    {{- $_action := include "base.string.normalize" (include "base.get" (list . "action")) | trim }}
    {{- if not $_action }}
      {{- fail "[definitions.containerRestartRule] action: required field is missing or empty" }}
    {{- end }}
    {{- if ne (lower $_action) "restart" }}
      {{- fail (printf "[definitions.containerRestartRule] action: '%s' is not one of 'restart'" $_action) }}
    {{- end }}
    {{- $action = "Restart" }}

    {{- $_exitCodesParsed := include "base.get" (list . "exitCodes") | fromYaml }}
    {{- if eq (include "base.isFromYamlError" $_exitCodesParsed) "true" }}
      {{- fail "[definitions.containerRestartRule] exitCodes: must be object type" }}
    {{- end }}
    {{- if not $_exitCodesParsed }}
      {{- fail "[definitions.containerRestartRule] exitCodes: required field is missing or empty" }}
    {{- end }}
    {{- $_exitCodes = $_exitCodesParsed }}

  {{- else }}
    {{- fail (printf "[definitions.containerRestartRule] input: must be string or object type, got '%s'" $_contextKind) }}
  {{- end }}

  {{- /* action（string, 必填）: 归一化后恒为 Restart，以带引号标量输出。 */ -}}
  {{- include "base.field" (list "action" $action "quote") }}

  {{- /* exitCodes（ContainerRestartRuleOnExitCodes, 必填）: 委托子模板渲染，空结果中断，非空时以 exitCodes 为父键输出。 */ -}}
  {{- $_exitCodesRendered := include "definitions.containerRestartRuleOnExitCodes" $_exitCodes | fromYaml }}
  {{- if eq (include "base.isFromYamlError" $_exitCodesRendered) "true" }}
    {{- fail "[definitions.containerRestartRule] exitCodes: invalid YAML output from definitions.containerRestartRuleOnExitCodes" }}
  {{- end }}
  {{- if not $_exitCodesRendered }}
    {{- fail "[definitions.containerRestartRule] exitCodes: definitions.containerRestartRuleOnExitCodes returned empty content" }}
  {{- end }}
  {{- include "base.field" (list "exitCodes" $_exitCodesRendered "base.map") }}
{{- end }}
