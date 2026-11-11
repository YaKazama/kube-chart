{{- /*
  渲染 Kubernetes NodeSelector 字段片段。

  行为 (按 K8s API 规范字段顺序):
    - nodeSelectorTerms (NodeSelectorTerm array, 必填): 取值并恢复为数组，逐项按 map 委托 definitions.nodeSelectorTerm，回收非空结果后以 base.field 输出。

  边界:
    - 只识别 nodeSelectorTerms 一个规范键；base.get 默认开启别名识别，因此 nodeSelectorTermsAlias 隐式生效，本模板不额外实现别名映射。
    - 入参只接受父级已归一化的 map 数组，本模板不解析字符串简写；取值缺失、为 null、为空字符串、为空数组或不是数组时中断，数组元素不是 map 时中断。
    - 每项按输入顺序处理与收集，不合并、去重或重排；委托结果为空内容的项不并入收集列表，收集结果为空时中断。
    - 本模板自身产生的失败消息使用 [definitions.nodeSelector] 前缀，条目级消息带 nodeSelectorTerms[<index>] 路径；definitions.nodeSelectorTerm 的失败消息保持其自身前缀与字段路径，本模板不改写或追加。
    - 除 nodeSelectorTerms 及其同级别名以外的入参字段静默忽略；不输出 status。

  入参: 上下文 map，必须包含以下字段:
    - nodeSelectorTerms (NodeSelectorTerm array, 必填) 节点选择器术语数组，术语之间为 OR 关系

  返回值: 可嵌入 requiredDuringSchedulingIgnoredDuringExecution 下的 NodeSelector YAML 字段片段，恒含 nodeSelectorTerms；非法入参中断渲染。

  示例:
    {{- include "definitions.nodeSelector" (dict "nodeSelectorTerms" (list (dict "matchExpressions" (list "a = b")))) }}
*/ -}}
{{- define "definitions.nodeSelector" -}}
  {{- /* nodeSelectorTerms（NodeSelectorTerm array, 必填）: 取值与别名识别由 base.get 承担，空输出、非数组与空数组中断；逐项按 map 委托 definitions.nodeSelectorTerm，非空结果按输入顺序收集，收集为空时中断，再以 base.field 输出。 */ -}}
  {{- $_nodeSelectorTermsRaw := include "base.get" (list . "nodeSelectorTerms") | trim }}
  {{- if not $_nodeSelectorTermsRaw }}
    {{- fail "[definitions.nodeSelector] nodeSelectorTerms: required field is missing or empty" }}
  {{- end }}
  {{- $_nodeSelectorTerms := fromYamlArray $_nodeSelectorTermsRaw }}
  {{- if eq (include "base.isFromYamlArrayError" $_nodeSelectorTerms) "true" }}
    {{- fail "[definitions.nodeSelector] nodeSelectorTerms: must be array type" }}
  {{- end }}

  {{- $rendered := list }}
  {{- range $index, $_term := $_nodeSelectorTerms }}
    {{- if not (kindIs "map" $_term) }}
      {{- fail (printf "[definitions.nodeSelector] nodeSelectorTerms[%d]: must be map type, got '%s'" $index (kindOf $_term)) }}
    {{- end }}

    {{- /* 委托子模板: 直接使用数组的 map 元素本体，不包装、不拆分；返回空内容时该项不并入收集列表。 */ -}}
    {{- $_termRendered := include "definitions.nodeSelectorTerm" $_term | fromYaml }}
    {{- if eq (include "base.isFromYamlError" $_termRendered) "true" }}
      {{- fail (printf "[definitions.nodeSelector] nodeSelectorTerms[%d]: definitions.nodeSelectorTerm returned invalid YAML" $index) }}
    {{- end }}
    {{- if $_termRendered }}
      {{- $rendered = mustAppend $rendered $_termRendered }}
    {{- end }}
  {{- end }}

  {{- /* 收集结果为空表示所有项均无有效内容，与取值缺失同样按 Required 为空中断。 */ -}}
  {{- if not $rendered }}
    {{- fail "[definitions.nodeSelector] nodeSelectorTerms: required field is missing or empty" }}
  {{- end }}
  {{- include "base.field" (list "nodeSelectorTerms" $rendered "base.slice") }}
{{- end }}
