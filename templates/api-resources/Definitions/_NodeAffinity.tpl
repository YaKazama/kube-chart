{{- /*
  渲染 Kubernetes NodeAffinity 字段片段。

  行为 (按 K8s API 规范字段顺序):
    - preferredDuringSchedulingIgnoredDuringExecution (PreferredSchedulingTerm array, 可选): 每项校验 weight 存在性并把 matchExpressions、matchFields 归一化为 preference 后逐项委托 definitions.preferredSchedulingTerm。
    - requiredDuringSchedulingIgnoredDuringExecution (NodeSelector, 可选): 每项归一化 matchExpressions、matchFields 后包裹为 nodeSelectorTerms，整体委托 definitions.nodeSelector。

  边界:
    - 只识别两个规范长键；读取时显式关闭 base.get 的同级 *Alias 识别，短键 preferred、required 与两个键的同级 *Alias 一律忽略。
    - 两个键的取值已由父级 definitions.affinity 归一化为 array；取值不是 array 时中断，元素不是 map 时中断。
    - 两个键均保持输入顺序，每项对应一项输出，不合并、不去重、不重排。
    - 每项只向下传递 matchExpressions 与 matchFields，两者各自识别同级 *Alias 并在为空时省略；两项都为空时仍委托子模板。
    - preferred 每项的 weight 必须存在且非空，缺失、null 或空字符串时中断；不是标量时中断；整数类型与 1 - 100 范围由 definitions.preferredSchedulingTerm 校验。
    - 子模板返回值不是合法 YAML 时中断；字段无有效内容时不输出该字段，两个字段均无有效内容时输出空字符串，不输出空 map。

  入参: 上下文 map，由 definitions.affinity 传入，可包含以下字段:
    - preferredDuringSchedulingIgnoredDuringExecution (PreferredSchedulingTerm array, 可选) 软性节点亲和性
    - requiredDuringSchedulingIgnoredDuringExecution (NodeSelector, 可选)                    硬性节点亲和性，取值由父级归一化为 nodeSelectorTerms array

  返回值: 可嵌入 affinity.nodeAffinity 下的 NodeAffinity YAML 字段片段；两个字段均无有效内容时为空字符串。

  示例:
    {{- include "definitions.nodeAffinity" (dict "requiredDuringSchedulingIgnoredDuringExecution" (list (dict "matchExpressions" (list (dict "key" "a" "operator" "In" "values" (list "b")))))) }}
*/ -}}
{{- define "definitions.nodeAffinity" -}}
  {{- $fields := list
        (dict "kind" "preferredDuringSchedulingIgnoredDuringExecution" "template" "definitions.preferredSchedulingTerm" "mode" "term")
        (dict "kind" "requiredDuringSchedulingIgnoredDuringExecution" "template" "definitions.nodeSelector" "mode" "nodeSelector") }}

  {{- /* preferredDuringSchedulingIgnoredDuringExecution、requiredDuringSchedulingIgnoredDuringExecution（可选）: 按固定顺序取值、归一化 term 并委托，两种模式的 term 归一化同构仅委托形态不同。 */ -}}
  {{- range $_field := $fields }}
    {{- $kind := $_field.kind }}
    {{- $_raw := include "base.get" (list $ $kind "" "" false false) | trim }}
    {{- if $_raw }}
      {{- $_terms := fromYamlArray $_raw }}
      {{- if eq (include "base.isFromYamlArrayError" $_terms) "true" }}
        {{- fail (printf "[definitions.nodeAffinity] %s: must be array type" $kind) }}
      {{- end }}

      {{- $terms := list }}
      {{- range $index, $_term := $_terms }}
        {{- if not (kindIs "map" $_term) }}
          {{- fail (printf "[definitions.nodeAffinity] %s[%d]: must be map type, got '%s'" $kind $index (kindOf $_term)) }}
        {{- end }}

        {{- /* matchExpressions、matchFields（NodeSelectorRequirement array, 可选）: 识别同级 *Alias 后按规范键写入本项，为空时不写入。 */ -}}
        {{- $cleaned := dict }}
        {{- range $_name := list "matchExpressions" "matchFields" }}
          {{- $_matchRaw := include "base.get" (list $_term $_name) | trim }}
          {{- if $_matchRaw }}
            {{- $_match := fromYamlArray $_matchRaw }}
            {{- if eq (include "base.isFromYamlArrayError" $_match) "true" }}
              {{- fail (printf "[definitions.nodeAffinity] %s[%d].%s: must be array type" $kind $index $_name) }}
            {{- end }}
            {{- if $_match }}
              {{- $_ := set $cleaned $_name $_match }}
            {{- end }}
          {{- end }}
        {{- end }}

        {{- /* weight（integer, 必填）: 只校验存在性与标量形态，取值与范围由 definitions.preferredSchedulingTerm 校验。 */ -}}
        {{- $entry := $cleaned }}
        {{- if eq $_field.mode "term" }}
          {{- $_weightRaw := include "base.get" (list $_term "weight") | trim }}
          {{- if not $_weightRaw }}
            {{- fail (printf "[definitions.nodeAffinity] %s[%d].weight: required field is missing or empty" $kind $index) }}
          {{- end }}
          {{- $_weightScalar := fromYaml (printf "v: %s" $_weightRaw) }}
          {{- if eq (include "base.isFromYamlError" $_weightScalar) "true" }}
            {{- fail (printf "[definitions.nodeAffinity] %s[%d].weight: must be scalar type" $kind $index) }}
          {{- end }}
          {{- $_weightValue := get $_weightScalar "v" }}
          {{- if or (kindIs "map" $_weightValue) (kindIs "slice" $_weightValue) }}
            {{- fail (printf "[definitions.nodeAffinity] %s[%d].weight: must be scalar type" $kind $index) }}
          {{- end }}
          {{- $entry = dict "weight" $_weightValue "preference" $cleaned }}
        {{- end }}

        {{- $terms = mustAppend $terms $entry }}
      {{- end }}

      {{- if $terms }}

        {{- /* preferred 逐项委托，required 包裹为 nodeSelectorTerms 整体委托；两者均以 base.field 输出。 */ -}}
        {{- if eq $_field.mode "term" }}
          {{- $rendered := list }}
          {{- range $index, $_term := $terms }}
            {{- $_termRendered := include $_field.template $_term | fromYaml }}
            {{- if eq (include "base.isFromYamlError" $_termRendered) "true" }}
              {{- fail (printf "[definitions.nodeAffinity] %s[%d]: %s returned invalid YAML" $kind $index $_field.template) }}
            {{- end }}
            {{- $rendered = mustAppend $rendered $_termRendered }}
          {{- end }}
          {{- include "base.field" (list $kind $rendered "base.slice") }}

        {{- else }}
          {{- $_rendered := include $_field.template (dict "nodeSelectorTerms" $terms) | fromYaml }}
          {{- if eq (include "base.isFromYamlError" $_rendered) "true" }}
            {{- fail (printf "[definitions.nodeAffinity] %s: %s returned invalid YAML" $kind $_field.template) }}
          {{- end }}
          {{- if $_rendered }}
            {{- include "base.field" (list $kind $_rendered "base.map") }}
          {{- end }}
        {{- end }}

      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}
