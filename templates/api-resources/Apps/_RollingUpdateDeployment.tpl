{{- /*
  渲染 Kubernetes RollingUpdateDeployment 字段片段。

  行为 (按 K8s API 规范字段顺序):
    - maxSurge (IntOrString, 可选): 按非负整数或非负百分比校验后渲染，百分比不设上限；缺失或为空时省略该字段。
    - maxUnavailable (IntOrString, 可选): 按非负整数或 0% 至 100% 的百分比校验后渲染；缺失或为空时省略该字段。
    - 两个字段同时等价于 0 时不输出任何字段，由 Kubernetes API 采用隐式默认值。
    - 委托 base.field 渲染时统一传入 base.rollingUpdate，由其在渲染前再做一次 IntOrString 格式校验。

  边界:
    - 入参是父级已清洗的 rollingUpdate map，本模板不解析 strategy 字符串简写，不补充 maxSurge、maxUnavailable 的 API 默认值。
    - 缺失、显式 null 与空字符串由 base.get 统一归并为空值，本模板不额外判定。
    - 小数部分非零、负数、带符号值与其他形态中断渲染；小数部分为 0 的原生浮点在 base.get 归一化时已与整数同形，本模板不做额外判定。
    - 只校验 IntOrString 形态与上述零值约束，不校验整数上限，也不校验百分比换算后的副本数关系。
    - 不输出 status 或其他字段。

  入参: 上下文 map，可包含以下字段:
    - maxSurge       (IntOrString, 可选) 可超出期望副本数的最大数量
    - maxUnavailable (IntOrString, 可选) 更新期间不可用的最大数量

  返回值: 可嵌入 spec.strategy.rollingUpdate 下的 RollingUpdateDeployment YAML 字段片段。

  示例:
    {{- include "apps.rollingUpdateDeployment" (dict "maxSurge" 1 "maxUnavailable" "30%") }}
*/ -}}
{{- define "apps.rollingUpdateDeployment" -}}
  {{- $_const := include "base.env" "" | fromYaml }}

  {{- /* maxSurge（IntOrString, 可选）: 剥离 YAML 标量引号后按 non-negative integer or percentage（百分比无上限）校验。 */ -}}
  {{- $maxSurge := "" }}
  {{- with include "base.get" (list . "maxSurge") | trim }}
    {{- $maxSurge = mustRegexReplaceAll $_const.SYS.YAML_QUOTED . "$1" | trim }}
    {{- if not (mustRegexMatch $_const.APPS.ROLLING_UPDATE.MAX_SURGE $maxSurge) }}
      {{- fail (printf "[apps.rollingUpdateDeployment] maxSurge: does not match %s, got '%s'" $_const.APPS.ROLLING_UPDATE.MAX_SURGE $maxSurge) }}
    {{- end }}
  {{- end }}

  {{- /* maxUnavailable（IntOrString, 可选）: 剥离 YAML 标量引号后按 non-negative integer or 0%-100% percentage 校验。 */ -}}
  {{- $maxUnavailable := "" }}
  {{- with include "base.get" (list . "maxUnavailable") | trim }}
    {{- $maxUnavailable = mustRegexReplaceAll $_const.SYS.YAML_QUOTED . "$1" | trim }}
    {{- if not (mustRegexMatch $_const.APPS.ROLLING_UPDATE.MAX_UNAVAILABLE $maxUnavailable) }}
      {{- fail (printf "[apps.rollingUpdateDeployment] maxUnavailable: does not match %s, got '%s'" $_const.APPS.ROLLING_UPDATE.MAX_UNAVAILABLE $maxUnavailable) }}
    {{- end }}
  {{- end }}

  {{- /* 两个字段同时等价于 0 时不输出任何字段，交由 API 采用隐式默认值，规避双向联动约束。 */ -}}
  {{- if not (and $maxSurge $maxUnavailable (empty (trimAll "0" (trimSuffix "%" $maxSurge))) (empty (trimAll "0" (trimSuffix "%" $maxUnavailable)))) }}
    {{- with $maxSurge }}
      {{- include "base.field" (list "maxSurge" . "base.rollingUpdate") }}
    {{- end }}
    {{- with $maxUnavailable }}
      {{- include "base.field" (list "maxUnavailable" . "base.rollingUpdate") }}
    {{- end }}
  {{- end }}
{{- end }}
