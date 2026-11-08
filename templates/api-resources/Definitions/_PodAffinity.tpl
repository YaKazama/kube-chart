{{- /*
  渲染 Kubernetes PodAffinity 字段片段。

  行为 (按 K8s API 规范字段顺序):
    - preferredDuringSchedulingIgnoredDuringExecution (WeightedPodAffinityTerm array, 可选): 每个元素归一化为只含 weight 与 podAffinityTerm 的上下文后委托 definitions.weightedPodAffinityTerm，按输入顺序收集。
    - requiredDuringSchedulingIgnoredDuringExecution (PodAffinityTerm array, 可选): 每个元素原样委托 definitions.podAffinityTerm，按输入顺序收集。

  边界:
    - 只识别两个规范长键；读取时显式关闭 base.get 的同级 *Alias 识别，短键 preferred、required 由父级 definitions.affinity 归一化，本层一律忽略。
    - preferred 元素的 weight 保留默认别名识别以支持 weightAlias；weight 必须是 integer 字面量，缺失、null、空字符串、带引号数字、浮点及其他类型均中断，1-100 范围由子模板校验。
    - preferred 元素除 weight、weightAlias 外其余字段原样放入 podAffinityTerm；元素已有 podAffinityTerm 时其余字段合并进该 map，同名键保留已有值；缺失时以空 map 为合并起点，不是 map 时中断；合并后仍为空 map 时按必填缺失中断。
    - required 元素只透传 map 本体；weight、topologyKey、labelSelector、namespaceSelector、matchLabelKeys、namespaces 等字段语义由子模板负责。
    - 字段取值不是 array 时中断；元素为 null 或空 map 时跳过；元素不是 map 时中断。
    - 子模板返回值不是合法 YAML 时中断；字段无有效元素时不输出该字段，两个字段均无有效内容时输出空字符串，不输出空 map。

  入参: 上下文 map，由 definitions.affinity 传入，可包含以下字段:
    - preferredDuringSchedulingIgnoredDuringExecution (WeightedPodAffinityTerm array, 可选) 软性 Pod 亲和性
    - requiredDuringSchedulingIgnoredDuringExecution (PodAffinityTerm array, 可选)           硬性 Pod 亲和性

  返回值: 可嵌入 podAffinity 下的 PodAffinity YAML 字段片段；两个字段均无有效内容时为空字符串。

  示例:
    {{- include "definitions.podAffinity" (dict "requiredDuringSchedulingIgnoredDuringExecution" (list (dict "topologyKey" "zone"))) }}
*/ -}}
{{- define "definitions.podAffinity" -}}

  {{- /* preferredDuringSchedulingIgnoredDuringExecution（WeightedPodAffinityTerm array, 可选）: 元素先归一化为只含 weight 与 podAffinityTerm 的上下文，再逐项委托 definitions.weightedPodAffinityTerm。 */ -}}
  {{- include "definitions.podAffinity.weightedTermList" (list $ "preferredDuringSchedulingIgnoredDuringExecution" "definitions.weightedPodAffinityTerm") }}

  {{- /* requiredDuringSchedulingIgnoredDuringExecution（PodAffinityTerm array, 可选）: 元素原样逐项委托 definitions.podAffinityTerm。 */ -}}
  {{- include "definitions.podAffinity.termList" (list $ "requiredDuringSchedulingIgnoredDuringExecution" "definitions.podAffinityTerm") }}
{{- end }}

{{- /*
  原样渲染 PodAffinity 中的单个术语数组字段。

  行为: 经 base.get 取值（显式关闭同级 *Alias），非空时解析为 array；元素必须为 map，空 map 与 null 元素跳过，其他类型中断；每个有效元素以本体作为上下文委托 termTemplate；返回值排除 YAML 解析错误后以 base.field 输出。

  入参: list [上下文, 字段名, 元素处理模板名]。

  边界: 只负责取值、类型门禁、元素跳过、逐项委托与字段输出；元素内部字段语义由被委托模板负责。

  返回值: 已渲染的字段片段；字段缺失、无有效元素或解析为空时不输出。

  示例:
    {{- include "definitions.podAffinity.termList" (list .Values.podAffinity "requiredDuringSchedulingIgnoredDuringExecution" "definitions.podAffinityTerm") }}
*/ -}}
{{- define "definitions.podAffinity.termList" -}}
  {{- $root := index . 0 }}
  {{- $kind := index . 1 }}
  {{- $termTemplate := index . 2 }}

  {{- $_raw := include "base.get" (list $root $kind "" "" false false) | trim }}
  {{- if $_raw }}
    {{- $_terms := fromYamlArray $_raw }}
    {{- if eq (include "base.isFromYamlArrayError" $_terms) "true" }}
      {{- fail (printf "[definitions.podAffinity] %s: must be array type" $kind) }}
    {{- end }}

    {{- $rendered := list }}
    {{- range $index, $_term := $_terms }}
      {{- if kindIs "map" $_term }}
        {{- if $_term }}
          {{- /* 委托子模板: 直接使用列表的 map 元素本体，不包装、不拆分。 */ -}}
          {{- $_termRendered := include $termTemplate $_term | fromYaml }}
          {{- if eq (include "base.isFromYamlError" $_termRendered) "true" }}
            {{- fail (printf "[definitions.podAffinity] %s[%d]: %s returned invalid YAML" $kind $index $termTemplate) }}
          {{- end }}
          {{- $rendered = mustAppend $rendered $_termRendered }}
        {{- end }}

      {{- else if not (kindIs "invalid" $_term) }}
        {{- fail (printf "[definitions.podAffinity] %s[%d]: must be map type, got '%s'" $kind $index (kindOf $_term)) }}
      {{- end }}
    {{- end }}

    {{- if $rendered }}
      {{- include "base.field" (list $kind $rendered "base.slice") }}
    {{- end }}
  {{- end }}
{{- end }}

{{- /*
  先归一化再渲染 PodAffinity 中的单个术语数组字段。

  行为: 经 base.get 取值（显式关闭同级 *Alias），非空时解析为 array；元素必须为 map，空 map 与 null 元素跳过，其他类型中断；每个有效元素先经 definitions.podAffinity.weightedTerm 归一化为只含 weight 与 podAffinityTerm 的上下文，再委托 termTemplate；返回值排除 YAML 解析错误后以 base.field 输出。

  入参: list [上下文, 字段名, 元素处理模板名]。

  边界: 只负责取值、类型门禁、元素跳过、上下文归一化、逐项委托与字段输出；归一化与元素内部字段语义分别由 definitions.podAffinity.weightedTerm 与被委托模板负责。

  返回值: 已渲染的字段片段；字段缺失、无有效元素或解析为空时不输出。

  示例:
    {{- include "definitions.podAffinity.weightedTermList" (list .Values.podAffinity "preferredDuringSchedulingIgnoredDuringExecution" "definitions.weightedPodAffinityTerm") }}
*/ -}}
{{- define "definitions.podAffinity.weightedTermList" -}}
  {{- $root := index . 0 }}
  {{- $kind := index . 1 }}
  {{- $termTemplate := index . 2 }}

  {{- $_raw := include "base.get" (list $root $kind "" "" false false) | trim }}
  {{- if $_raw }}
    {{- $_terms := fromYamlArray $_raw }}
    {{- if eq (include "base.isFromYamlArrayError" $_terms) "true" }}
      {{- fail (printf "[definitions.podAffinity] %s: must be array type" $kind) }}
    {{- end }}

    {{- $rendered := list }}
    {{- range $index, $_term := $_terms }}
      {{- if kindIs "map" $_term }}
        {{- if $_term }}
          {{- /* 委托子模板: 归一化后的 weight 与 podAffinityTerm 上下文，不含原元素其余键。 */ -}}
          {{- $context := include "definitions.podAffinity.weightedTerm" (list $_term $kind $index) | fromYaml }}
          {{- $_termRendered := include $termTemplate $context | fromYaml }}
          {{- if eq (include "base.isFromYamlError" $_termRendered) "true" }}
            {{- fail (printf "[definitions.podAffinity] %s[%d]: %s returned invalid YAML" $kind $index $termTemplate) }}
          {{- end }}
          {{- $rendered = mustAppend $rendered $_termRendered }}
        {{- end }}

      {{- else if not (kindIs "invalid" $_term) }}
        {{- fail (printf "[definitions.podAffinity] %s[%d]: must be map type, got '%s'" $kind $index (kindOf $_term)) }}
      {{- end }}
    {{- end }}

    {{- if $rendered }}
      {{- include "base.field" (list $kind $rendered "base.slice") }}
    {{- end }}
  {{- end }}
{{- end }}

{{- /*
  把 preferred 元素归一化为 WeightedPodAffinityTerm 的委托上下文。

  行为: weight 经 base.get 取值并保留默认别名识别，缺失或为空时中断，原始 YAML 文本必须匹配整数正则；podAffinityTerm 已有值作为合并起点，缺失或空 map 按空 map 接受，不是 map 时中断；除 weight、weightAlias、podAffinityTerm 外的其余术语字段原样并入 podAffinityTerm，同名键保留已有值；合并后仍为空 map 时中断。

  入参: list [元素 map, 子结构名, 元素下标]。

  边界: 只做上下文归一化，包含 weight 的整数形态校验与 podAffinityTerm 合并；不校验 weight 取值范围，也不渲染任何字段。

  返回值: 可 fromYaml 解析且恒含 weight 与 podAffinityTerm 两个键的 YAML 映射文本。

  示例:
    {{- include "definitions.podAffinity.weightedTerm" (list $term "preferredDuringSchedulingIgnoredDuringExecution" 0) | fromYaml }}
*/ -}}
{{- define "definitions.podAffinity.weightedTerm" -}}
  {{- $const := include "base.env" "" | fromYaml }}
  {{- $term := index . 0 }}
  {{- $kind := index . 1 }}
  {{- $index := index . 2 }}

  {{- /* weight（integer, 必填）: 默认别名识别支持 weightAlias；原始 YAML 文本直接匹配 TYPES.INT，带引号数字、浮点及其他类型一律中断，范围由子模板校验。 */ -}}
  {{- $_weightRaw := include "base.get" (list $term "weight") | trim }}
  {{- if not $_weightRaw }}
    {{- fail (printf "[definitions.podAffinity] %s[%d].weight: required field is missing or empty" $kind $index) }}
  {{- end }}
  {{- if not (mustRegexMatch $const.TYPES.INT $_weightRaw) }}
    {{- fail (printf "[definitions.podAffinity] %s[%d].weight: must be integer type, got '%s'" $kind $index $_weightRaw) }}
  {{- end }}
  {{- $weight := int64 $_weightRaw }}

  {{- /* podAffinityTerm（PodAffinityTerm, 必填）: 元素已有值作为合并起点，缺失或空 map 按空 map 接受，同名键保留已有值。 */ -}}
  {{- $_podTermRaw := include "base.get" (list $term "podAffinityTerm" "" "" false false) | trim }}
  {{- $podTerm := dict }}
  {{- if $_podTermRaw }}
    {{- $_parsed := fromYaml $_podTermRaw }}
    {{- if eq (include "base.isFromYamlError" $_parsed) "true" }}
      {{- fail (printf "[definitions.podAffinity] %s[%d].podAffinityTerm: must be map type" $kind $index) }}
    {{- end }}
    {{- if not (kindIs "map" $_parsed) }}
      {{- fail (printf "[definitions.podAffinity] %s[%d].podAffinityTerm: must be map type, got '%s'" $kind $index (kindOf $_parsed)) }}
    {{- end }}
    {{- if $_parsed }}
      {{- $podTerm = $_parsed }}
    {{- end }}
  {{- end }}

  {{- /* weight、weightAlias、podAffinityTerm 不参与合并，其余术语字段原样并入 podAffinityTerm；合并后仍为空 map 时中断。 */ -}}
  {{- $rest := mustDeepCopy $term }}
  {{- $_ := unset $rest "weight" }}
  {{- $_ := unset $rest "weightAlias" }}
  {{- $_ := unset $rest "podAffinityTerm" }}
  {{- $_ := mustMerge $podTerm $rest }}
  {{- if not $podTerm }}
    {{- fail (printf "[definitions.podAffinity] %s[%d].podAffinityTerm: required field is missing or empty" $kind $index) }}
  {{- end }}

  {{- toYamlPretty (dict "weight" $weight "podAffinityTerm" $podTerm) }}
{{- end }}
