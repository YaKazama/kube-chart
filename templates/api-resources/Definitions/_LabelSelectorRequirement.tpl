{{- /*
  渲染 Kubernetes LabelSelectorRequirement 字段片段。

  行为 (按 K8s API 规范字段顺序):
    - key (string, 必填): 校验存在性与 string 类型，再按 Kubernetes 标签键语法拆分校验；缺失或类型非法中断。
    - operator (string, 必填): 校验存在性与 string 类型，枚举通过 base.field 的允许值列表校验；缺失、类型非法或取值超出允许范围中断。
    - values (string array, 可选): 仅真值非空时委托 base.field 与 base.slice 渲染；缺失或空 array 不输出该字段。

  边界:
    - 入参是父级已归一化的单项 map，本模板不解析字符串简写，不调用 base.get，不做类型转换。
    - 不判断 values 与 operator 的适用性；In/NotIn 的 values 存在性与数组类型由父级负责。
    - 不清理 values 元素，不输出 status 或其他字段。
    - 本模板主动产生的失败消息使用 [definitions.labelSelectorRequirement] 前缀；委托 base.field、base.slice 时保留其自身前缀。

  入参: 上下文 map，可包含以下字段:
    - key      (string, 必填)       标签键，可含可选前缀段
    - operator (string, 必填)       In、NotIn、Exists、DoesNotExist，大小写敏感
    - values   (string array, 可选) 标签值列表

  返回值: 可嵌入 LabelSelectorRequirement YAML 字段片段；非法入参中断渲染。

  示例:
    {{- include "definitions.labelSelectorRequirement" (dict "key" "app.kubernetes.io/name" "operator" "In" "values" (list "web" "api")) }}
*/ -}}
{{- define "definitions.labelSelectorRequirement" -}}
  {{- $const := include "base.env" "" | fromYaml }}

  {{- /* key（string, 必填）: 校验存在性与 string 类型，再按标签键语法分段校验。 */ -}}
  {{- if not (hasKey . "key") }}
    {{- fail "[definitions.labelSelectorRequirement] key: required field is missing" }}
  {{- end }}
  {{- $key := get . "key" }}
  {{- if not (kindIs "string" $key) }}
    {{- fail (printf "[definitions.labelSelectorRequirement] key: must be string type, got '%s'" (kindOf $key)) }}
  {{- end }}

  {{- /* 按单个斜杠拆分为可选前缀段与必填名称段，多个斜杠归属整体 key。 */ -}}
  {{- $_segments := splitList "/" $key }}
  {{- if gt (len $_segments) 2 }}
    {{- fail (printf "[definitions.labelSelectorRequirement] key: '%s' allows at most one '/' separator" $key) }}
  {{- end }}
  {{- $name := mustLast $_segments }}
  {{- $prefix := "" }}
  {{- $hasPrefix := eq (len $_segments) 2 }}
  {{- if $hasPrefix }}
    {{- $prefix = mustFirst $_segments }}
  {{- end }}

  {{- if not (mustRegexMatch $const.K8S.SELECTOR.KEY_NAME_FOR_APPS $name) }}
    {{- fail (printf "[definitions.labelSelectorRequirement] key.name: '%s' must be 1-63 characters, start and end with [A-Za-z0-9], and contain only [A-Za-z0-9_.-]" $name) }}
  {{- end }}

  {{- if $hasPrefix }}
    {{- if not (mustRegexMatch $const.K8S.SELECTOR.KEY_PREFIX_FOR_APPS $prefix) }}
      {{- fail (printf "[definitions.labelSelectorRequirement] key.prefix: '%s' must be dot-separated DNS labels of 1-63 lowercase alphanumeric or '-' characters, each starting and ending with [a-z0-9]" $prefix) }}
    {{- end }}
    {{- if gt (len $prefix) 253 }}
      {{- fail (printf "[definitions.labelSelectorRequirement] key.prefix: '%s' exceeds 253 characters" $prefix) }}
    {{- end }}
  {{- end }}
  {{- include "base.field" (list "key" $key "base.rawString") }}

  {{- /* operator（string, 必填）: 校验存在性与 string 类型后，以允许值列表委托 base.field 渲染。 */ -}}
  {{- if not (hasKey . "operator") }}
    {{- fail "[definitions.labelSelectorRequirement] operator: required field is missing" }}
  {{- end }}
  {{- $operator := get . "operator" }}
  {{- if not (kindIs "string" $operator) }}
    {{- fail (printf "[definitions.labelSelectorRequirement] operator: must be string type, got '%s'" (kindOf $operator)) }}
  {{- end }}
  {{- include "base.field" (list "operator" $operator "" (list "In" "NotIn" "Exists" "DoesNotExist")) }}

  {{- /* values（string array, 可选）: 仅非空时委托 base.field 与 base.slice 渲染，类型门禁与序列化由其承担。 */ -}}
  {{- $values := get . "values" }}
  {{- if $values }}
    {{- include "base.field" (list "values" $values "base.slice") }}
  {{- end }}
{{- end }}
