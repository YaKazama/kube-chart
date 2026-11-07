{{- /*
  渲染 Kubernetes Affinity 字段片段。

  行为 (按 K8s API 规范字段顺序):
    - nodeAffinity    (NodeAffinity, 可选): 归一化后仍有内容时委托 definitions.nodeAffinity。
    - podAffinity     (PodAffinity, 可选): 归一化后仍有内容时委托 definitions.podAffinity。
    - podAntiAffinity (PodAntiAffinity, 可选): 归一化后仍有内容时委托 definitions.podAntiAffinity。

  边界:
    - 三类子结构同构处理，按固定键列表取值；取值不是 map 时中断。
    - preferred、required 分别是 preferredDuringSchedulingIgnoredDuringExecution、requiredDuringSchedulingIgnoredDuringExecution 的显式短键；两者不互斥，取值优先级为「短键同级 <叶子>Alias > 短键 > 长键同级 <叶子>Alias > 长键」，短键为空或缺失时退化取长键，两者都为空时不向下传递。
    - 只向下传递两个规范长键，子结构内的其余字段丢弃；不解析、不重排、不校验子模板内部结构。
    - 子模板返回值不是合法 YAML 时中断；三类子结构均无有效内容时输出空字符串，不输出空 map。

  入参: 上下文 map，可包含以下字段:
    - nodeAffinity    (NodeAffinity, 可选)    节点亲和性调度规则
    - podAffinity     (PodAffinity, 可选)     Pod 亲和性调度规则
    - podAntiAffinity (PodAntiAffinity, 可选) Pod 反亲和性调度规则

  返回值: 可嵌入 affinity 下的 Affinity YAML 字段片段；三类子结构均无有效内容时为空字符串。

  示例:
    {{- include "definitions.affinity" (dict "podAffinity" (dict "required" (list (dict "topologyKey" "zone")))) }}
*/ -}}
{{- define "definitions.affinity" -}}
  {{- $substructures := list
        (dict "kind" "nodeAffinity" "template" "definitions.nodeAffinity")
        (dict "kind" "podAffinity" "template" "definitions.podAffinity")
        (dict "kind" "podAntiAffinity" "template" "definitions.podAntiAffinity") }}
  {{- $keyPairs := list (list "preferred" "preferredDuringSchedulingIgnoredDuringExecution") (list "required" "requiredDuringSchedulingIgnoredDuringExecution") }}

  {{- /* nodeAffinity、podAffinity、podAntiAffinity（可选）: 按固定顺序同构取值，非 map 中断，归一化结果非空时委托对应子模板并输出。 */ -}}
  {{- range $_item := $substructures }}
    {{- $kind := $_item.kind }}
    {{- $_raw := include "base.get" (list $ $kind "" "" false false) | trim }}
    {{- if $_raw }}
      {{- $_sub := $_raw | fromYaml }}
      {{- if eq (include "base.isFromYamlError" $_sub) "true" }}
        {{- fail (printf "[definitions.affinity] %s: must be map type" $kind) }}
      {{- end }}

      {{- if $_sub }}
        {{- $normalized := dict }}

        {{- /* preferredDuringSchedulingIgnoredDuringExecution、requiredDuringSchedulingIgnoredDuringExecution: 短键非空优先，为空退化长键，双空不输出。 */ -}}
        {{- range $_pair := $keyPairs }}
          {{- $_shortKey := index $_pair 0 }}
          {{- $_longKey := index $_pair 1 }}
          {{- $_shortValues := include "base.get" (list $_sub $_shortKey) | fromYamlArray }}
          {{- if eq (include "base.isFromYamlArrayError" $_shortValues) "true" }}
            {{- fail (printf "[definitions.affinity] %s.%s: must be array type" $kind $_shortKey) }}
          {{- end }}
          {{- $_longValues := include "base.get" (list $_sub $_longKey) | fromYamlArray }}
          {{- if eq (include "base.isFromYamlArrayError" $_longValues) "true" }}
            {{- fail (printf "[definitions.affinity] %s.%s: must be array type" $kind $_longKey) }}
          {{- end }}
          {{- $values := default $_longValues $_shortValues }}
          {{- if $values }}
            {{- $_ := set $normalized $_longKey $values }}
          {{- end }}
        {{- end }}

        {{- if $normalized }}
          {{- $_rendered := include $_item.template $normalized | fromYaml }}
          {{- if eq (include "base.isFromYamlError" $_rendered) "true" }}
            {{- fail (printf "[definitions.affinity] %s: %s returned invalid YAML" $kind $_item.template) }}
          {{- end }}
          {{- if $_rendered }}
            {{- include "base.field" (list $kind $_rendered "base.map") }}
          {{- end }}
        {{- end }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}
