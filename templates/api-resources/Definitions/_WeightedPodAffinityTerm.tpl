{{- /*
  渲染 Kubernetes WeightedPodAffinityTerm 字段片段。

  行为 (按 K8s API 文档字段顺序):
    - podAffinityTerm (PodAffinityTerm, 必填): 经 base.get 必填取值，解析为 map 后整 map 原样委托 definitions.podAffinityTerm，返回值排除解析错误后以 base.field 输出。
    - weight (integer, 必填): 经 base.get 必填取值，剥离 YAML 标量引号后委托 base.int 校验整数形态并归一化，再由 base.int.range 校验 1 - 100 闭区间，最后以 base.field 输出。

  边界:
    - 只识别 podAffinityTerm 与 weight 两个规范键；base.get 默认开启别名识别，因此 podAffinityTermAlias、weightAlias 隐式生效，本模板不额外实现别名映射。
    - podAffinityTerm 缺失、为 null 或为空 map 时由 base.get 必填校验中断；取值不是 map 时中断。
    - weight 缺失、为 null 或为空字符串时由 base.get 必填校验中断；带引号数字剥离引号后按整数接受；不是整数形态、为浮点、布尔、map 或 list 时中断；超出 1 - 100 时中断。
    - 本模板不解析 podAffinityTerm 内部的 topologyKey、labelSelector、namespaceSelector、matchLabelKeys、namespaces，内部结构由 definitions.podAffinityTerm 负责。
    - 子模板返回值不是合法 YAML 时中断；除 podAffinityTerm、weight 以外的入参字段静默忽略；不输出 status。

  入参: 上下文 map，由 definitions.podAffinity 传入，恒含以下字段:
    - podAffinityTerm  (PodAffinityTerm, 必填) 与权重关联的 Pod 亲和性术语
    - weight           (integer, 必填)         软性亲和性权重，1 - 100

  返回值: 可嵌入 preferredDuringSchedulingIgnoredDuringExecution 单个元素的 YAML 字段片段。

  示例:
    {{- include "definitions.weightedPodAffinityTerm" (dict "weight" 11 "podAffinityTerm" (dict "topologyKey" "kubernetes.io/hostname")) }}
*/ -}}
{{- define "definitions.weightedPodAffinityTerm" -}}
  {{- $const := include "base.env" "" | fromYaml }}

  {{- /* podAffinityTerm（PodAffinityTerm, 必填）: 必填取值后解析为 map，整 map 原样委托子模板；非 map 或子模板返回非法 YAML 时中断。 */ -}}
  {{- $podTerm := include "base.get" (list . "podAffinityTerm" "" "" true) | fromYaml }}
  {{- if eq (include "base.isFromYamlError" $podTerm) "true" }}
    {{- fail "[definitions.weightedPodAffinityTerm] podAffinityTerm: must be map type" }}
  {{- end }}
  {{- if not (kindIs "map" $podTerm) }}
    {{- fail (printf "[definitions.weightedPodAffinityTerm] podAffinityTerm: must be map type, got '%s'" (kindOf $podTerm)) }}
  {{- end }}
  {{- $_podTermRendered := include "definitions.podAffinityTerm" $podTerm | fromYaml }}
  {{- if eq (include "base.isFromYamlError" $_podTermRendered) "true" }}
    {{- fail "[definitions.weightedPodAffinityTerm] podAffinityTerm: definitions.podAffinityTerm returned invalid YAML" }}
  {{- end }}
  {{- include "base.field" (list "podAffinityTerm" $_podTermRendered "base.map") }}

  {{- /* weight（integer, 必填）: base.get 承担必填取值与别名识别，剥离 YAML 标量引号后委托 base.int 校验整数形态，再由 base.int.range 校验闭区间。 */ -}}
  {{- $_weightRaw := include "base.get" (list . "weight" "" "" true) | trim }}
  {{- $weight := int64 (include "base.int" (mustRegexReplaceAll $const.SYS.YAML_QUOTED $_weightRaw "$1" | trim)) }}
  {{- include "base.field" (list "weight" (include "base.int.range" (list $weight 1 100)) "base.int") }}
{{- end }}
