{{- /*
  渲染 Kubernetes NodeAffinity 字段片段。

  行为 (按 K8s API 规范字段顺序):
    - preferredDuringSchedulingIgnoredDuringExecution (PreferredSchedulingTerm array, 可选): 每项校验 weight 存在性并把 matchExpressions、matchFields 归一化为必填 preference 后逐项委托 definitions.preferredSchedulingTerm。
    - requiredDuringSchedulingIgnoredDuringExecution (NodeSelector, 可选): 每项归一化 matchExpressions、matchFields 后包裹为 nodeSelectorTerms，整体委托 definitions.nodeSelector。

  边界:
    - 只识别两个规范长键；读取时显式关闭 base.get 的同级 *Alias 识别，短键 preferred、required 与两个键的同级 *Alias 一律忽略。
    - 两个键的取值已由父级 definitions.affinity 归一化为 array；取值不是 array 时中断，元素不是 map 时中断。
    - 两个键均保持输入顺序，每项对应一项输出，不合并、不去重、不重排。
    - 每项只向下传递 matchExpressions 与 matchFields，两者各自识别同级 *Alias 并在为空时省略；preferred 项两者都为空时本层中断，required 项两者都为空时仍委托子模板。
    - preferred 每项的 weight 必须存在且非空，缺失、null 或空字符串时中断；标量形态与 1 - 100 范围由 definitions.preferredSchedulingTerm 校验，纯数字字符串被其拒绝。
    - 子模板返回值不是合法 YAML 时中断；字段无有效内容时不输出该字段，两个字段均无有效内容时输出空字符串，不输出空 map。

  入参: 上下文 map，由 definitions.affinity 传入，可包含以下字段:
    - preferredDuringSchedulingIgnoredDuringExecution (PreferredSchedulingTerm array, 可选) 软性节点亲和性
    - requiredDuringSchedulingIgnoredDuringExecution (NodeSelector, 可选)                    硬性节点亲和性，取值由父级归一化为 nodeSelectorTerms array

  返回值: 可嵌入 affinity.nodeAffinity 下的 NodeAffinity YAML 字段片段；两个字段均无有效内容时为空字符串。

  示例:
    {{- include "definitions.nodeAffinity" (dict "requiredDuringSchedulingIgnoredDuringExecution" (list (dict "matchExpressions" (list (dict "key" "a" "operator" "In" "values" (list "b")))))) }}
*/ -}}
{{- define "definitions.nodeAffinity" -}}
  {{- /* preferredDuringSchedulingIgnoredDuringExecution（PreferredSchedulingTerm array, 可选）: 元素必须为 map，matchExpressions 与 matchFields 归一化后必须至少一项非空，连同必填 weight 逐项委托 definitions.preferredSchedulingTerm。 */ -}}
  {{- $_preferredRaw := include "base.get" (list . "preferredDuringSchedulingIgnoredDuringExecution" "" "" false false) | trim }}
  {{- if $_preferredRaw }}
    {{- $_preferred := fromYamlArray $_preferredRaw }}
    {{- if eq (include "base.isFromYamlArrayError" $_preferred) "true" }}
      {{- fail "[definitions.nodeAffinity] preferredDuringSchedulingIgnoredDuringExecution: must be array type" }}
    {{- end }}

    {{- $terms := list }}
    {{- range $index, $_term := $_preferred }}
      {{- if not (kindIs "map" $_term) }}
        {{- fail (printf "[definitions.nodeAffinity] preferredDuringSchedulingIgnoredDuringExecution[%d]: must be map type, got '%s'" $index (kindOf $_term)) }}
      {{- end }}

      {{- /* matchExpressions、matchFields（NodeSelectorRequirement array, 可选）: 各自识别同级 *Alias，为空时省略对应键。 */ -}}
      {{- $_matchExpressions := include "definitions.nodeAffinity.matchList" (list $_term "preferredDuringSchedulingIgnoredDuringExecution" "matchExpressions" $index) | fromYamlArray }}
      {{- $_matchFields := include "definitions.nodeAffinity.matchList" (list $_term "preferredDuringSchedulingIgnoredDuringExecution" "matchFields" $index) | fromYamlArray }}
      {{- $preference := dict }}
      {{- if $_matchExpressions }}
        {{- $_ := set $preference "matchExpressions" $_matchExpressions }}
      {{- end }}
      {{- if $_matchFields }}
        {{- $_ := set $preference "matchFields" $_matchFields }}
      {{- end }}

      {{- /* weight（integer, 必填）: 只校验存在性，把 base.get 原始文本直接交给子模板；标量形态与 1 - 100 范围均由 definitions.preferredSchedulingTerm 的 base.int、base.int.range 收口。 */ -}}
      {{- $_weightRaw := include "base.get" (list $_term "weight") | trim }}
      {{- if not $_weightRaw }}
        {{- fail (printf "[definitions.nodeAffinity] preferredDuringSchedulingIgnoredDuringExecution[%d].weight: required field is missing or empty" $index) }}
      {{- end }}

      {{- /* preference（NodeSelectorTerm, 必填）: matchExpressions 与 matchFields 归一化后都为空时本层直接中断，不向子模板传递空 map。 */ -}}
      {{- if not $preference }}
        {{- fail (printf "[definitions.nodeAffinity] preferredDuringSchedulingIgnoredDuringExecution[%d].preference: required field is missing or empty" $index) }}
      {{- end }}

      {{- $terms = mustAppend $terms (dict "weight" $_weightRaw "preference" $preference) }}
    {{- end }}

    {{- if $terms }}
      {{- /* 逐项委托 definitions.preferredSchedulingTerm，返回值排除 YAML 解析错误后以 base.field 输出。 */ -}}
      {{- $rendered := list }}
      {{- range $index, $_term := $terms }}
        {{- $_termRendered := include "definitions.preferredSchedulingTerm" $_term | fromYaml }}
        {{- if eq (include "base.isFromYamlError" $_termRendered) "true" }}
          {{- fail (printf "[definitions.nodeAffinity] preferredDuringSchedulingIgnoredDuringExecution[%d]: definitions.preferredSchedulingTerm returned invalid YAML" $index) }}
        {{- end }}
        {{- $rendered = mustAppend $rendered $_termRendered }}
      {{- end }}
      {{- include "base.field" (list "preferredDuringSchedulingIgnoredDuringExecution" $rendered "base.slice") }}
    {{- end }}
  {{- end }}

  {{- /* requiredDuringSchedulingIgnoredDuringExecution（NodeSelectorTerm array, 可选）: 元素必须为 map，matchExpressions 与 matchFields 归一化后包裹为 nodeSelectorTerms 整体委托 definitions.nodeSelector。 */ -}}
  {{- $_requiredRaw := include "base.get" (list . "requiredDuringSchedulingIgnoredDuringExecution" "" "" false false) | trim }}
  {{- if $_requiredRaw }}
    {{- $_required := fromYamlArray $_requiredRaw }}
    {{- if eq (include "base.isFromYamlArrayError" $_required) "true" }}
      {{- fail "[definitions.nodeAffinity] requiredDuringSchedulingIgnoredDuringExecution: must be array type" }}
    {{- end }}

    {{- $terms := list }}
    {{- range $index, $_term := $_required }}
      {{- if not (kindIs "map" $_term) }}
        {{- fail (printf "[definitions.nodeAffinity] requiredDuringSchedulingIgnoredDuringExecution[%d]: must be map type, got '%s'" $index (kindOf $_term)) }}
      {{- end }}

      {{- /* matchExpressions、matchFields（NodeSelectorRequirement array, 可选）: 各自识别同级 *Alias，为空时省略对应键。 */ -}}
      {{- $_matchExpressions := include "definitions.nodeAffinity.matchList" (list $_term "requiredDuringSchedulingIgnoredDuringExecution" "matchExpressions" $index) | fromYamlArray }}
      {{- $_matchFields := include "definitions.nodeAffinity.matchList" (list $_term "requiredDuringSchedulingIgnoredDuringExecution" "matchFields" $index) | fromYamlArray }}
      {{- $term := dict }}
      {{- if $_matchExpressions }}
        {{- $_ := set $term "matchExpressions" $_matchExpressions }}
      {{- end }}
      {{- if $_matchFields }}
        {{- $_ := set $term "matchFields" $_matchFields }}
      {{- end }}

      {{- $terms = mustAppend $terms $term }}
    {{- end }}

    {{- if $terms }}
      {{- /* 包裹为 nodeSelectorTerms 整体委托 definitions.nodeSelector，返回值排除 YAML 解析错误后以 base.field 输出。 */ -}}
      {{- $_rendered := include "definitions.nodeSelector" (dict "nodeSelectorTerms" $terms) | fromYaml }}
      {{- if eq (include "base.isFromYamlError" $_rendered) "true" }}
        {{- fail "[definitions.nodeAffinity] requiredDuringSchedulingIgnoredDuringExecution: definitions.nodeSelector returned invalid YAML" }}
      {{- end }}
      {{- if $_rendered }}
        {{- include "base.field" (list "requiredDuringSchedulingIgnoredDuringExecution" $_rendered "base.map") }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}

{{- /*
  归一化单个 NodeSelectorTerm 元素中的 matchExpressions 或 matchFields。

  行为: 经 base.get 取值（保留默认别名识别），非空时解析为 array；取值不是 array 时中断，解析结果为空时输出空字符串。

  入参: list [元素 map, 子结构名, 字段名, 元素下标]。

  边界: 只做单个字段的取值、类型门禁与解析；不校验数组元素内部结构，也不判断元素本身是否为 map。

  返回值: 可 fromYamlArray 解析的 YAML 列表文本；字段缺失、为空或解析为空时为空字符串。

  示例:
    {{- include "definitions.nodeAffinity.matchList" (list $term "nodeAffinity" "matchExpressions" 0) | fromYamlArray }}
*/ -}}
{{- define "definitions.nodeAffinity.matchList" -}}
  {{- $term := index . 0 }}
  {{- $kind := index . 1 }}
  {{- $name := index . 2 }}
  {{- $index := index . 3 }}

  {{- $_raw := include "base.get" (list $term $name) | trim }}
  {{- if $_raw }}
    {{- $_match := fromYamlArray $_raw }}
    {{- if eq (include "base.isFromYamlArrayError" $_match) "true" }}
      {{- fail (printf "[definitions.nodeAffinity] %s[%d].%s: must be array type" $kind $index $name) }}
    {{- end }}
    {{- if $_match }}
      {{- toYamlPretty $_match }}
    {{- end }}
  {{- end }}
{{- end }}
