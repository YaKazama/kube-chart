{{- /*
  渲染 Kubernetes LabelSelectorRequirement 字段片段。

  行为 (按 K8s API 规范字段顺序):
    - key (string, 必填): 经 base.get 取值（内含必填校验与别名识别），按 YAML 标量语义解码后由 base.labelKey 校验标签键语法；缺失、为 null 或空字符串中断。
    - operator (string, 必填): 经 base.get 取值（内含必填校验与别名识别），按 YAML 标量语义解码后由 base.field 的允许值列表校验枚举；缺失、为 null、空字符串或取值超出允许范围中断。
    - values (string array, 可选): 转换后为空时不输出该字段；非 array 中断，元素统一转为 string。

  边界:
    - 入参是父级已归一化的单项 map，本模板不解析字符串简写，不做类型转换。
    - 不判断 values 与 operator 的适用性；In/NotIn 的 values 存在性与数组类型由父级负责。
    - 标签键语法完全由 base.labelKey 校验，失败消息使用本模板名与字段路径 key。
    - 不清理 values 元素，不逐个校验元素类型，不输出 status 或其他字段。
    - 本模板主动产生的失败消息使用 [definitions.labelSelectorRequirement] 前缀；标签键语法失败同样使用该前缀；其余委托 base.get、base.field、base.slice 时保留其自身前缀。

  入参: 上下文 map，可包含以下字段:
    - key           (string, 必填)       标签键，可含可选前缀段
    - operator      (string, 必填)       In、NotIn、Exists、DoesNotExist，大小写敏感
    - values        (string array, 可选) 标签值列表，元素非 string 时强制转字符串
    - keyAlias      (string, 可选)       内置别名，非空时优先于 key
    - operatorAlias (string, 可选)       内置别名，非空时优先于 operator
    - valuesAlias   (string array, 可选) 内置别名，非空时优先于 values

  返回值: 可嵌入 LabelSelectorRequirement YAML 字段片段；非法入参中断渲染。

  示例:
    {{- include "definitions.labelSelectorRequirement" (dict "key" "app.kubernetes.io/name" "operator" "In" "values" (list "web" "api")) }}
*/ -}}
{{- define "definitions.labelSelectorRequirement" -}}
  {{- /* key（string, 必填）: base.get 承担多层取值、别名识别与必填校验，base.string.normalize 按 YAML 标量语义解码，标签键语法交由 base.labelKey 校验。 */ -}}
  {{- $key := include "base.labelKey" (list (include "base.string.normalize" (include "base.get" (list . "key" "" "" true)) | trim) "definitions.labelSelectorRequirement" "key") }}
  {{- include "base.field" (list "key" $key "base.rawString") }}

  {{- /* operator（string, 必填）: base.get 承担取值与必填校验，base.string.normalize 解码后由 base.field 的允许值列表校验。 */ -}}
  {{- $operator := include "base.string.normalize" (include "base.get" (list . "operator" "" "" true)) | trim }}
  {{- include "base.field" (list "operator" $operator "" (list "In" "NotIn" "Exists" "DoesNotExist")) }}

  {{- /* values（string array, 可选）: 缺失、空 array 与 null 均不输出；非 array 中断，元素统一转为 string，转换后为空也按空处理。 */ -}}
  {{- $_valuesRaw := include "base.get" (list . "values") | fromYamlArray }}
  {{- if eq (include "base.isFromYamlArrayError" $_valuesRaw) "true" }}
    {{- fail "[definitions.labelSelectorRequirement] values: must be array type" }}
  {{- end }}
  {{- $values := toStrings $_valuesRaw }}
  {{- if $values }}
    {{- include "base.field" (list "values" $values "base.slice") }}
  {{- end }}
{{- end }}
