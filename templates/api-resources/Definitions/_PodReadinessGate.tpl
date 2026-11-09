{{- /*
  渲染 Kubernetes PodReadinessGate 字段片段。

  行为 (按 K8s API 规范字段顺序):
    - conditionType (string, 可选): 经 base.get 取值，去除首尾空白与 YAML 标量引号；为空时不输出该字段，非空时以带引号标量输出。

  边界:
    - 只输出 conditionType，不包含父级键；readinessGates 数组的循环、字符串简写归一化、条目合并与去重由调用方负责。
    - base.get 默认开启别名识别，因此同级 conditionTypeAlias 隐式生效，本模板不额外实现别名映射。
    - conditionType 不是 string 时以本模板前缀中断；不校验取值合法性。
    - 除 conditionType 及其同级别名以外的入参字段静默忽略；不输出 status、apiVersion、kind。

  入参: 上下文 map，由父级传入单个 readinessGate 描述，可包含以下字段:
    - conditionType (string, 可选) 与 Pod conditions 中 conditionType 匹配的条件类型

  返回值: 可嵌入 readinessGates 数组元素的 PodReadinessGate YAML 字段片段；conditionType 为空时为空内容。

  示例:
    {{- include "definitions.podReadinessGate" (dict "conditionType" "www.example.com/ready") }}  // conditionType: "www.example.com/ready"
*/ -}}
{{- define "definitions.podReadinessGate" -}}
  {{- $const := include "base.env" "" | fromYaml }}

  {{- /* conditionType（string, 可选）: 空值跳过；非空时去引号后以带引号标量输出，避免 on、yes 等文本被父级解析为布尔值。 */ -}}
  {{- $_conditionTypeRaw := include "base.get" (list . "conditionType") | trim }}
  {{- if $_conditionTypeRaw }}
    {{- /* 类型判定必须在去引号之前: 布尔与数值经 base.get 会序列化为同形文本，'"on"' 保留引号时才恢复为 string。 */ -}}
    {{- if not (kindIs "string" (fromYaml (printf "v: %s" $_conditionTypeRaw)).v) }}
      {{- fail (printf "[definitions.podReadinessGate] conditionType: must be string type, got '%s'" $_conditionTypeRaw) }}
    {{- end }}
    {{- $conditionType := mustRegexReplaceAll $const.SYS.YAML_QUOTED $_conditionTypeRaw "$1" | trim }}
    {{- if $conditionType }}
      {{- include "base.field" (list "conditionType" $conditionType "quote") }}
    {{- end }}
  {{- end }}
{{- end }}
