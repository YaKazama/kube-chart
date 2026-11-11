{{- /*
  渲染 Kubernetes Affinity 字段片段。

  行为 (按 K8s API 规范字段顺序):
    - nodeAffinity    (NodeAffinity, 可选): 归一化后仍有内容时委托 definitions.nodeAffinity。
    - podAffinity     (PodAffinity, 可选): 归一化后仍有内容时委托 definitions.podAffinity。
    - podAntiAffinity (PodAntiAffinity, 可选): 归一化后仍有内容时委托 definitions.podAntiAffinity。

  边界:
    - 三类子结构各自独立取值，取值不是 map 时中断。
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
  {{- /* nodeAffinity（NodeAffinity, 可选）: 解析为 map 后按短键优先归一化两个调度键，归一化结果非空时委托 definitions.nodeAffinity 并输出。 */ -}}
  {{- $_nodeAffinityRaw := include "base.get" (list . "nodeAffinity" "" "" false false) | trim }}
  {{- if $_nodeAffinityRaw }}
    {{- $_nodeAffinity := fromYaml $_nodeAffinityRaw }}
    {{- if eq (include "base.isFromYamlError" $_nodeAffinity) "true" }}
      {{- fail "[definitions.affinity] nodeAffinity: must be map type" }}
    {{- end }}
    {{- if $_nodeAffinity }}
      {{- $normalized := dict }}
      {{- $_preferred := include "definitions.affinity.schedulingTerm" (list $_nodeAffinity "nodeAffinity" "preferred" "preferredDuringSchedulingIgnoredDuringExecution") | fromYamlArray }}
      {{- if $_preferred }}
        {{- $_ := set $normalized "preferredDuringSchedulingIgnoredDuringExecution" $_preferred }}
      {{- end }}
      {{- $_required := include "definitions.affinity.schedulingTerm" (list $_nodeAffinity "nodeAffinity" "required" "requiredDuringSchedulingIgnoredDuringExecution") | fromYamlArray }}
      {{- if $_required }}
        {{- $_ := set $normalized "requiredDuringSchedulingIgnoredDuringExecution" $_required }}
      {{- end }}
      {{- if $normalized }}
        {{- $_rendered := include "definitions.nodeAffinity" $normalized | fromYaml }}
        {{- if eq (include "base.isFromYamlError" $_rendered) "true" }}
          {{- fail "[definitions.affinity] nodeAffinity: definitions.nodeAffinity returned invalid YAML" }}
        {{- end }}
        {{- if $_rendered }}
          {{- include "base.field" (list "nodeAffinity" $_rendered "base.map") }}
        {{- end }}
      {{- end }}
    {{- end }}
  {{- end }}

  {{- /* podAffinity（PodAffinity, 可选）: 同 nodeAffinity，委托 definitions.podAffinity。 */ -}}
  {{- $_podAffinityRaw := include "base.get" (list . "podAffinity" "" "" false false) | trim }}
  {{- if $_podAffinityRaw }}
    {{- $_podAffinity := fromYaml $_podAffinityRaw }}
    {{- if eq (include "base.isFromYamlError" $_podAffinity) "true" }}
      {{- fail "[definitions.affinity] podAffinity: must be map type" }}
    {{- end }}
    {{- if $_podAffinity }}
      {{- $normalized := dict }}
      {{- $_preferred := include "definitions.affinity.schedulingTerm" (list $_podAffinity "podAffinity" "preferred" "preferredDuringSchedulingIgnoredDuringExecution") | fromYamlArray }}
      {{- if $_preferred }}
        {{- $_ := set $normalized "preferredDuringSchedulingIgnoredDuringExecution" $_preferred }}
      {{- end }}
      {{- $_required := include "definitions.affinity.schedulingTerm" (list $_podAffinity "podAffinity" "required" "requiredDuringSchedulingIgnoredDuringExecution") | fromYamlArray }}
      {{- if $_required }}
        {{- $_ := set $normalized "requiredDuringSchedulingIgnoredDuringExecution" $_required }}
      {{- end }}
      {{- if $normalized }}
        {{- $_rendered := include "definitions.podAffinity" $normalized | fromYaml }}
        {{- if eq (include "base.isFromYamlError" $_rendered) "true" }}
          {{- fail "[definitions.affinity] podAffinity: definitions.podAffinity returned invalid YAML" }}
        {{- end }}
        {{- if $_rendered }}
          {{- include "base.field" (list "podAffinity" $_rendered "base.map") }}
        {{- end }}
      {{- end }}
    {{- end }}
  {{- end }}

  {{- /* podAntiAffinity（PodAntiAffinity, 可选）: 同 nodeAffinity，委托 definitions.podAntiAffinity。 */ -}}
  {{- $_podAntiAffinityRaw := include "base.get" (list . "podAntiAffinity" "" "" false false) | trim }}
  {{- if $_podAntiAffinityRaw }}
    {{- $_podAntiAffinity := fromYaml $_podAntiAffinityRaw }}
    {{- if eq (include "base.isFromYamlError" $_podAntiAffinity) "true" }}
      {{- fail "[definitions.affinity] podAntiAffinity: must be map type" }}
    {{- end }}
    {{- if $_podAntiAffinity }}
      {{- $normalized := dict }}
      {{- $_preferred := include "definitions.affinity.schedulingTerm" (list $_podAntiAffinity "podAntiAffinity" "preferred" "preferredDuringSchedulingIgnoredDuringExecution") | fromYamlArray }}
      {{- if $_preferred }}
        {{- $_ := set $normalized "preferredDuringSchedulingIgnoredDuringExecution" $_preferred }}
      {{- end }}
      {{- $_required := include "definitions.affinity.schedulingTerm" (list $_podAntiAffinity "podAntiAffinity" "required" "requiredDuringSchedulingIgnoredDuringExecution") | fromYamlArray }}
      {{- if $_required }}
        {{- $_ := set $normalized "requiredDuringSchedulingIgnoredDuringExecution" $_required }}
      {{- end }}
      {{- if $normalized }}
        {{- $_rendered := include "definitions.podAntiAffinity" $normalized | fromYaml }}
        {{- if eq (include "base.isFromYamlError" $_rendered) "true" }}
          {{- fail "[definitions.affinity] podAntiAffinity: definitions.podAntiAffinity returned invalid YAML" }}
        {{- end }}
        {{- if $_rendered }}
          {{- include "base.field" (list "podAntiAffinity" $_rendered "base.map") }}
        {{- end }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}

{{- /*
  归一化 Affinity 子结构中的单个调度键。

  行为: 短键与长键各自经 base.get 取值（保留默认别名识别），任一取值不是 array 时中断；短键取值非空时优先，为空或缺失时回退长键，两者都为空时输出空字符串。

  入参: list [子结构 map, 子结构名, 短键, 长键]。

  边界: 只做单个键对的取值、类型门禁与优先级选择；不判断子结构是否为空，也不委托任何子模板。

  返回值: 可 fromYamlArray 解析的 YAML 列表文本；两个键都无有效内容时为空字符串。

  示例:
    {{- include "definitions.affinity.schedulingTerm" (list .Values.podAffinity "podAffinity" "preferred" "preferredDuringSchedulingIgnoredDuringExecution") | fromYamlArray }}
*/ -}}
{{- define "definitions.affinity.schedulingTerm" -}}
  {{- $sub := index . 0 }}
  {{- $kind := index . 1 }}
  {{- $shortKey := index . 2 }}
  {{- $longKey := index . 3 }}

  {{- /* 短键、长键: 非空短键优先，短键为空时退化长键；任一取值不是 array 时中断并带子结构与字段路径。 */ -}}
  {{- $_shortValues := include "base.get" (list $sub $shortKey) | fromYamlArray }}
  {{- if eq (include "base.isFromYamlArrayError" $_shortValues) "true" }}
    {{- fail (printf "[definitions.affinity] %s.%s: must be array type" $kind $shortKey) }}
  {{- end }}
  {{- $_longValues := include "base.get" (list $sub $longKey) | fromYamlArray }}
  {{- if eq (include "base.isFromYamlArrayError" $_longValues) "true" }}
    {{- fail (printf "[definitions.affinity] %s.%s: must be array type" $kind $longKey) }}
  {{- end }}
  {{- $values := default $_longValues $_shortValues }}
  {{- if $values }}
    {{- toYamlPretty $values }}
  {{- end }}
{{- end }}
