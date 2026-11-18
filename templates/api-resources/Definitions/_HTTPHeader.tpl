{{- /*
  渲染 Kubernetes HTTPHeader 字段片段。

  行为 (按 K8s API 规范字段顺序):
    - name  (string, 必填): 去除首尾空白后必须非空，并以带引号标量输出。
    - value (string, 必填): 去除首尾空白后必须非空，并以带引号标量输出。

  边界:
    - 只输出 name、value，不包含父级键、apiVersion 或 kind。
    - 任一字段缺失、为 null、为空字符串或仅含空白时中断。
    - 任一字段不是 string 时由 base.string.normalize 中断，失败消息使用其自身前缀。
    - base.get 默认开启别名识别，因此同级 nameAlias、valueAlias 隐式生效。
    - 除 name、value 及其同级别名以外的入参字段静默忽略。
    - 输出值去除首尾空白；不校验 HTTPHeader 名称或值的协议语法。

  入参: 上下文 map，必须包含以下字段:
    - name  (string, 必填) HTTPHeader 名称
    - value (string, 必填) HTTPHeader 值

  返回值: 可嵌入 HTTPHeader array 元素的 YAML 字段片段。

  示例:
    {{- include "definitions.httpHeader" (dict "name" "X-Foo" "value" "bar") }}
    // name: "X-Foo"
    // value: "bar"
*/ -}}
{{- define "definitions.httpHeader" -}}
  {{- /* name、value（string, 必填）: 按官方字段顺序逐个经 base.string.normalize 解码并 trim；trim 后为空时中断，非空时以带引号标量输出。 */ -}}
  {{- range $field := list "name" "value" }}
    {{- $value := include "base.string.normalize" (include "base.get" (list $ $field)) | trim }}
    {{- if not $value }}
      {{- fail (printf "[definitions.httpHeader] %s: required field is missing or empty" $field) }}
    {{- end }}
    {{- include "base.field" (list $field $value "quote") }}
  {{- end }}
{{- end }}
