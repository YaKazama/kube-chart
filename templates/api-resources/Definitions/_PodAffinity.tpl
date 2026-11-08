{{- /*
  渲染 Kubernetes PodAffinity 字段片段。

  行为 (按 K8s API 规范字段顺序):
    - preferredDuringSchedulingIgnoredDuringExecution (WeightedPodAffinityTerm array, 可选): 每个元素原样委托 definitions.weightedPodAffinityTerm，按输入顺序收集。
    - requiredDuringSchedulingIgnoredDuringExecution (PodAffinityTerm array, 可选): 每个元素原样委托 definitions.podAffinityTerm，按输入顺序收集。

  边界:
    - 只识别两个规范长键；读取时显式关闭 base.get 的同级 *Alias 识别，短键 preferred、required 由父级 definitions.affinity 归一化，本层一律忽略。
    - 只透传数组元素的 map 本体，不拆分、不重组、不校验元素内部字段；weight、topologyKey、labelSelector、namespaceSelector、matchLabelKeys、namespaces 等字段由子模板负责。
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
  {{- $fields := list
        (dict "kind" "preferredDuringSchedulingIgnoredDuringExecution" "template" "definitions.weightedPodAffinityTerm")
        (dict "kind" "requiredDuringSchedulingIgnoredDuringExecution" "template" "definitions.podAffinityTerm") }}

  {{- /* preferredDuringSchedulingIgnoredDuringExecution、requiredDuringSchedulingIgnoredDuringExecution（可选）: 按固定顺序关闭别名取值，元素原样委托对应术语子模板。 */ -}}
  {{- range $_field := $fields }}
    {{- $kind := $_field.kind }}
    {{- $_raw := include "base.get" (list $ $kind "" "" false false) | trim }}
    {{- if $_raw }}
      {{- $_terms := fromYamlArray $_raw }}
      {{- if eq (include "base.isFromYamlArrayError" $_terms) "true" }}
        {{- fail (printf "[definitions.podAffinity] %s: must be array type" $kind) }}
      {{- end }}

      {{- $rendered := list }}
      {{- range $index, $_term := $_terms }}
        {{- if kindIs "map" $_term }}
          {{- if $_term }}
            {{- $_termRendered := include $_field.template $_term | fromYaml }}
            {{- if eq (include "base.isFromYamlError" $_termRendered) "true" }}
              {{- fail (printf "[definitions.podAffinity] %s[%d]: %s returned invalid YAML" $kind $index $_field.template) }}
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
{{- end }}
