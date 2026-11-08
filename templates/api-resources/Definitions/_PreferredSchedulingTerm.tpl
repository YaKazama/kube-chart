{{- /*
  渲染 Kubernetes PreferredSchedulingTerm 字段片段。

  行为 (按 K8s API 规范字段顺序):
    - weight (integer, 必填): 经 base.get 必填取值，剥离 YAML 标量引号后委托 base.int 校验整数形态并归一化，再由 base.int.range 校验 1 - 100 闭区间，最后以 base.field 输出。
    - preference (NodeSelectorTerm, 必填): 经 base.get 必填取值，缺失、null、空字符串与空 map 由必填校验中断，解析后按 map 恢复，整 map 原样委托 definitions.nodeSelectorTerm，返回值排除解析错误且非空后以 base.field 输出。

  边界:
    - 只识别 weight 与 preference 两个规范键；base.get 默认开启别名识别，因此 weightAlias、preferenceAlias 隐式生效，本模板不额外实现别名映射。
    - weight 缺失、为 null 或空字符串时由 base.get 必填校验中断；不是整数形态、为浮点、布尔、map 或 list 时中断；超出 1 - 100 时中断。
    - preference 缺失、为 null、为空字符串或为空 map 时由 base.get 必填校验中断；取值不是 map 时中断；子模板返回空内容或非法 YAML 时中断。
    - 失败消息按产出方归属：必填校验使用 [base.get] 前缀，类型判定与子模板边界使用 [definitions.preferredSchedulingTerm] 前缀。
    - 本模板不解析 preference 内部的 matchExpressions、matchFields 及其字符串简写，内部结构由 definitions.nodeSelectorTerm 负责。
    - 除 weight、preference 以外的入参字段静默忽略；不输出 status。

  入参: 上下文 map，必须包含以下字段:
    - weight      (integer, 必填)         软性亲和性权重，1 - 100
    - preference  (NodeSelectorTerm, 必填) 软性亲和性选择条件

  返回值: 可嵌入 preferredDuringSchedulingIgnoredDuringExecution 单个元素的 YAML 字段片段，恒含 weight 与 preference。

  示例:
    {{- include "definitions.preferredSchedulingTerm" (dict "weight" 1 "preference" (dict "matchExpressions" (list (dict "key" "a" "operator" "In" "values" (list "b"))))) }}
*/ -}}
{{- define "definitions.preferredSchedulingTerm" -}}
  {{- $const := include "base.env" "" | fromYaml }}

  {{- /* weight（integer, 必填）: base.get 承担必填取值与别名识别，剥离 YAML 标量引号后委托 base.int 校验整数形态，再由 base.int.range 校验闭区间。 */ -}}
  {{- $_weightRaw := include "base.get" (list . "weight" "" "" true) | trim }}
  {{- $weight := int64 (include "base.int" (mustRegexReplaceAll $const.SYS.YAML_QUOTED $_weightRaw "$1" | trim)) }}
  {{- include "base.field" (list "weight" (include "base.int.range" (list $weight 1 100)) "base.int") }}

  {{- /* preference（NodeSelectorTerm, 必填）: base.get 必填取值承担必填校验与别名识别，缺失、null、空字符串与空 map 由其直接中断；解析后按 map 恢复，非 map、子模板返回非法 YAML 或空内容时由本模板中断。 */ -}}
  {{- $_preference := include "base.get" (list . "preference" "" "" true) | fromYaml }}
  {{- if eq (include "base.isFromYamlError" $_preference) "true" }}
    {{- fail "[definitions.preferredSchedulingTerm] preference: must be map type" }}
  {{- end }}
  {{- if not (kindIs "map" $_preference) }}
    {{- fail (printf "[definitions.preferredSchedulingTerm] preference: must be map type, got '%s'" (kindOf $_preference)) }}
  {{- end }}
  {{- $_preferenceRendered := include "definitions.nodeSelectorTerm" $_preference | fromYaml }}
  {{- if eq (include "base.isFromYamlError" $_preferenceRendered) "true" }}
    {{- fail "[definitions.preferredSchedulingTerm] preference: definitions.nodeSelectorTerm returned invalid YAML" }}
  {{- end }}
  {{- if not $_preferenceRendered }}
    {{- fail "[definitions.preferredSchedulingTerm] preference: required field is missing or empty" }}
  {{- end }}
  {{- include "base.field" (list "preference" $_preferenceRendered "base.map") }}
{{- end }}
