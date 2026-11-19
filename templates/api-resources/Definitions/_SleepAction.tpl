{{- /*
  渲染 Kubernetes SleepAction 字段片段。

  行为 (按 K8s API 规范字段顺序):
    - seconds (integer): 通过 base.get 取值；缺失、null 与空字符串不输出。合法值必须为 int、int64 或整值 float64，并位于 [1, 9007199254740991] 闭区间，最终按 integer 渲染。

  边界:
    - 只输出 seconds，不包含 sleep、postStart、preStop 或 lifecycle 父键，也不输出 apiVersion、kind 或 status。
    - base.get 默认识别同级 secondsAlias，本模板不重复处理别名；除此以外的入参字段静默忽略。
    - seconds 在官方 API 中为必填字段；本模板按调用方约定把缺失、null 与空字符串视为未配置，输出空内容且不中断渲染。
    - 字符串、bool、非整值 float64、slice 与 map 均中断；0、负数与超过 float64 安全整数上限的取值同样中断。
    - 不校验 sleep 时长在 Kubernetes 运行时的实际约束。

  入参: 上下文 map，可包含 seconds (integer)；同级 secondsAlias 由 base.get 隐式识别。

  返回值: 可嵌入 sleep 位置的 YAML 字段片段；seconds 缺失、为 null 或空字符串时为空内容。

  示例:
    {{- include "definitions.sleepAction" (dict "seconds" 30) }}  // seconds: 30
*/ -}}
{{- define "definitions.sleepAction" -}}
  {{- /* seconds（integer）: 取值后跳过缺失、null 与空字符串，回读原生类型并完成整数语义和范围校验。 */ -}}
  {{- $_raw := include "base.get" (list . "seconds") | trim }}
  {{- if $_raw }}
    {{- $_parsed := fromYaml (printf "seconds: %s" $_raw) }}
    {{- if eq (include "base.isFromYamlError" $_parsed) "true" }}
      {{- fail (printf "[definitions.sleepAction] seconds: must be integer, got '%s'" $_raw) }}
    {{- end }}

    {{- $_value := get $_parsed "seconds" }}
    {{- $_kind := kindOf $_value }}
    {{- if not (has $_kind (list "int" "int64" "float64")) }}
      {{- fail (printf "[definitions.sleepAction] seconds: must be integer, got '%v' (kind: %s)" $_value $_kind) }}
    {{- end }}

    {{- $seconds := float64 $_value }}
    {{- if ne $seconds (floor $seconds) }}
      {{- fail (printf "[definitions.sleepAction] seconds: must be integer, got '%v'" $_value) }}
    {{- end }}
    {{- $_ := include "base.int.range" (list $seconds 1.0 9007199254740991.0) }}

    {{- include "base.field" (list "seconds" (int $seconds) "base.int") }}
  {{- end }}
{{- end }}
