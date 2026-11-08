{{- /*
  渲染 Kubernetes PodAffinityTerm 字段片段。

  行为 (按 K8s API 文档字段顺序):
    - labelSelector (LabelSelector, 可选): 经 base.get 取值，解析为 map 后整 map 委托 definitions.labelSelector，返回值排除解析错误后以 base.field 输出。
    - matchLabelKeys (string array, 可选): 经 base.get 取值，逐项按标签键语法校验并去重去空，再以 base.field 输出。
    - mismatchLabelKeys (string array, 可选): 同 matchLabelKeys。
    - namespaceSelector (LabelSelector, 可选): 同 labelSelector。
    - namespaces (string array, 可选): 经 base.get 取值，按逗号或空白拆分并剔除空项，逐项按 RFC1123 校验、去重后归一为 string 列表，再以 base.field 输出。
    - topologyKey (string, 必填): 经 base.get 必填取值，还原 YAML 标量类型确认 string 后剥离引号并按标签键语法校验，最后以 base.field 输出。

  边界:
    - 只识别六个规范键；base.get 默认开启别名识别，因此 <键名>Alias 隐式生效，本模板不额外实现别名映射。
    - 除六个字段及其同级别名以外的入参字段静默忽略；不输出 status。
    - 选择器字段缺失、为 null 或为空 map 时不输出；不是 map 或子模板返回非法 YAML 时中断。
    - 键数组字段不是 array 时中断；列表项不满足标签键语法时中断；去重去空后为空时不输出。
    - namespaces 不是 array 时中断；拆分后任一项不满足命名空间名语法时中断；清洗后为空时不输出。
    - topologyKey 缺失、为 null、为空字符串、不是 string 或不符合标签键语法时中断。
    - 本模板不解析 labelSelector、namespaceSelector 内部的 matchExpressions、matchLabels，内部结构由 definitions.labelSelector 负责。

  入参: 上下文 map，由 definitions.podAffinity 的 required 元素或 definitions.weightedPodAffinityTerm 的 podAffinityTerm 传入，可包含以下字段:
    - labelSelector      (LabelSelector, 可选)  标签选择器
    - matchLabelKeys     (string array, 可选)   参与匹配的 Pod 标签键
    - mismatchLabelKeys  (string array, 可选)   参与排除的 Pod 标签键
    - namespaceSelector  (LabelSelector, 可选)  命名空间选择器
    - namespaces         (string array, 可选)   命名空间名列表，支持逗号或空格分隔
    - topologyKey        (string, 必填)         拓扑域标签键

  返回值: 可嵌入 requiredDuringSchedulingIgnoredDuringExecution 单个元素或 podAffinityTerm 下的 PodAffinityTerm YAML 字段片段。

  示例:
    {{- include "definitions.podAffinityTerm" (dict "topologyKey" "topology.kubernetes.io/zone" "labelSelector" (dict "matchLabels" (dict "app" "web"))) }}
*/ -}}
{{- define "definitions.podAffinityTerm" -}}
  {{- $const := include "base.env" "" | fromYaml }}

  {{- /* labelSelector（LabelSelector, 可选）: 解析后按 map 恢复，空 map 与子模板空内容均不输出；非 map 或子模板返回非法 YAML 时中断。 */ -}}
  {{- $_labelSelectorRaw := include "base.get" (list $ "labelSelector") | trim }}
  {{- if $_labelSelectorRaw }}
    {{- $_labelSelector := fromYaml $_labelSelectorRaw }}
    {{- if eq (include "base.isFromYamlError" $_labelSelector) "true" }}
      {{- fail "[definitions.podAffinityTerm] labelSelector: must be map type" }}
    {{- end }}
    {{- if not (kindIs "map" $_labelSelector) }}
      {{- fail (printf "[definitions.podAffinityTerm] labelSelector: must be map type, got '%s'" (kindOf $_labelSelector)) }}
    {{- end }}
    {{- if $_labelSelector }}
      {{- $_rendered := include "definitions.labelSelector" $_labelSelector | fromYaml }}
      {{- if eq (include "base.isFromYamlError" $_rendered) "true" }}
        {{- fail "[definitions.podAffinityTerm] labelSelector: definitions.labelSelector returned invalid YAML" }}
      {{- end }}
      {{- if $_rendered }}
        {{- include "base.field" (list "labelSelector" $_rendered "base.map") }}
      {{- end }}
    {{- end }}
  {{- end }}

  {{- /* matchLabelKeys（string array, 可选）: 逐项 trim 后跳过空项，按标签键语法校验并去重；非 array 时中断，去重后为空时不输出。 */ -}}
  {{- $_matchLabelKeysRaw := include "base.get" (list $ "matchLabelKeys") | fromYamlArray }}
  {{- if eq (include "base.isFromYamlArrayError" $_matchLabelKeysRaw) "true" }}
    {{- fail "[definitions.podAffinityTerm] matchLabelKeys: must be array type" }}
  {{- end }}
  {{- $matchLabelKeys := list }}
  {{- range $_item := $_matchLabelKeysRaw }}
    {{- $_key := toString $_item | trim }}
    {{- if $_key }}
      {{- $matchLabelKeys = mustAppend $matchLabelKeys (include "base.labelKey" $_key) }}
    {{- end }}
  {{- end }}
  {{- $matchLabelKeys = mustUniq $matchLabelKeys }}
  {{- if $matchLabelKeys }}
    {{- include "base.field" (list "matchLabelKeys" $matchLabelKeys "base.slice") }}
  {{- end }}

  {{- /* mismatchLabelKeys（string array, 可选）: 同 matchLabelKeys。 */ -}}
  {{- $_mismatchLabelKeysRaw := include "base.get" (list $ "mismatchLabelKeys") | fromYamlArray }}
  {{- if eq (include "base.isFromYamlArrayError" $_mismatchLabelKeysRaw) "true" }}
    {{- fail "[definitions.podAffinityTerm] mismatchLabelKeys: must be array type" }}
  {{- end }}
  {{- $mismatchLabelKeys := list }}
  {{- range $_item := $_mismatchLabelKeysRaw }}
    {{- $_key := toString $_item | trim }}
    {{- if $_key }}
      {{- $mismatchLabelKeys = mustAppend $mismatchLabelKeys (include "base.labelKey" $_key) }}
    {{- end }}
  {{- end }}
  {{- $mismatchLabelKeys = mustUniq $mismatchLabelKeys }}
  {{- if $mismatchLabelKeys }}
    {{- include "base.field" (list "mismatchLabelKeys" $mismatchLabelKeys "base.slice") }}
  {{- end }}

  {{- /* namespaceSelector（LabelSelector, 可选）: 同 labelSelector。 */ -}}
  {{- $_namespaceSelectorRaw := include "base.get" (list $ "namespaceSelector") | trim }}
  {{- if $_namespaceSelectorRaw }}
    {{- $_namespaceSelector := fromYaml $_namespaceSelectorRaw }}
    {{- if eq (include "base.isFromYamlError" $_namespaceSelector) "true" }}
      {{- fail "[definitions.podAffinityTerm] namespaceSelector: must be map type" }}
    {{- end }}
    {{- if not (kindIs "map" $_namespaceSelector) }}
      {{- fail (printf "[definitions.podAffinityTerm] namespaceSelector: must be map type, got '%s'" (kindOf $_namespaceSelector)) }}
    {{- end }}
    {{- if $_namespaceSelector }}
      {{- $_rendered := include "definitions.labelSelector" $_namespaceSelector | fromYaml }}
      {{- if eq (include "base.isFromYamlError" $_rendered) "true" }}
        {{- fail "[definitions.podAffinityTerm] namespaceSelector: definitions.labelSelector returned invalid YAML" }}
      {{- end }}
      {{- if $_rendered }}
        {{- include "base.field" (list "namespaceSelector" $_rendered "base.map") }}
      {{- end }}
    {{- end }}
  {{- end }}

  {{- /* namespaces（string array, 可选）: 按逗号或空白拆分并剔除空项，逐项按 RFC1123 校验、去重后归一为 string 列表；非 array 或命名空间名非法时中断。 */ -}}
  {{- $_namespacesRaw := include "base.get" (list $ "namespaces") | fromYamlArray }}
  {{- if eq (include "base.isFromYamlArrayError" $_namespacesRaw) "true" }}
    {{- fail "[definitions.podAffinityTerm] namespaces: must be array type" }}
  {{- end }}
  {{- if $_namespacesRaw }}
    {{- $namespaces := list }}
    {{- range $_item := include "base.slice.cleanup" (list $_namespacesRaw $const.SPLIT.SPACE_COMMA) | fromYamlArray }}
      {{- $namespaces = mustAppend $namespaces (include "base.string.verify" (list (toString $_item) $const.RFC.RFC1123)) }}
    {{- end }}
    {{- $namespaces = toStrings ($namespaces | mustUniq) }}
    {{- if $namespaces }}
      {{- include "base.field" (list "namespaces" $namespaces "base.slice") }}
    {{- end }}
  {{- end }}

  {{- /* topologyKey（string, 必填）: 必填取值后还原 YAML 标量类型确认 string，剥离引号后按标签键语法校验；缺失、非 string 或语法非法时中断。 */ -}}
  {{- $_topologyKeyRaw := include "base.get" (list $ "topologyKey" "" "" true) | trim }}
  {{- if not (kindIs "string" (fromYaml (printf "v: %s" $_topologyKeyRaw)).v) }}
    {{- fail (printf "[definitions.podAffinityTerm] topologyKey: must be string type, got '%s'" $_topologyKeyRaw) }}
  {{- end }}
  {{- $topologyKey := include "base.labelKey" (mustRegexReplaceAll $const.SYS.YAML_QUOTED $_topologyKeyRaw "$1") }}
  {{- include "base.field" (list "topologyKey" $topologyKey "base.rawString") }}
{{- end }}
