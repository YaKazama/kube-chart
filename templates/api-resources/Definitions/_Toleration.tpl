{{- /*
  渲染 Kubernetes Toleration 字段片段。

  行为 (按 K8s API 规范字段顺序):
    - effect            (string, 可选): 非空时按 NoExecute、NoSchedule、PreferNoSchedule 枚举校验后以带引号标量输出。
    - key               (string, 可选): 非空时以带引号标量输出。
    - operator          (string, 可选): 非空时按 Equal、Exists、Gt、Lt 枚举校验后以带引号标量输出；省略时不输出，不填充默认值 Equal。
    - tolerationSeconds (integer, 可选): 非空时按整数输出，显式 0 与负数均原样保留。
    - value             (string, 可选): 非空时以带引号标量输出。

  互斥校验:
    - key、operator、value 至少一个有值时校验三者组合，三者均无值时跳过校验。
    - key 为空时 operator 必须为 Exists，包括 operator 省略的情况。
    - operator 为 Exists 时 value 必须为空。
    - operator 为 Gt 或 Lt 时 value 必须非空。

  边界:
    - 只输出当前层字段，不输出 tolerations 父键、apiVersion 或 kind；五个字段均不生效时输出空内容。
    - 字符串字段缺失、为 null、为空字符串或只含空白时按未提供处理：跳过输出，并在互斥校验中视为空值。
    - 字符串字段不是 string 时由 base.string.normalize 中断，不做类型归一化。
    - operator 枚举比较大小写敏感，exists、equal 等非精确匹配由 base.field 中断并给出合法范围。
    - tolerationSeconds 只接受原生整数；整数型字符串经 base.get 序列化为带引号文本后由 base.int 中断。
    - 字符串与枚举字段统一以双引号输出，避免 on、yes、true 等文本在父级回收后被解析为布尔。
    - base.get 默认开启别名识别，因此各字段同级 <字段>Alias 隐式生效。
    - 除五个字段及其同级别名以外的入参字段静默忽略；不输出 status。

  入参: 上下文 map，可全部省略以下字段:
    - effect            (string, 可选)  要匹配的 taint effect
    - key               (string, 可选)  容忍的 taint 键，为空表示匹配所有键
    - operator          (string, 可选)  key 与 value 的关系
    - tolerationSeconds (integer, 可选) 容忍 NoExecute taint 的时长
    - value             (string, 可选)  容忍匹配的 taint 值

  返回值: 可嵌入 tolerations 元素下的 Toleration YAML 字段片段；无有效内容时为空内容。

  示例:
    {{- include "definitions.toleration" (dict "key" "node-role.kubernetes.io/control-plane" "operator" "Exists" "effect" "NoSchedule") }}
      // effect: "NoSchedule"
      // key: "node-role.kubernetes.io/control-plane"
      // operator: "Exists"
*/ -}}
{{- define "definitions.toleration" -}}
  {{- /* effect、key、operator、value（string, 可选）: 先行归一并 trim，互斥校验与后续逐字段输出共用同一份结果。 */ -}}
  {{- $effect := include "base.string.normalize" (include "base.get" (list . "effect")) | trim }}
  {{- $key := include "base.string.normalize" (include "base.get" (list . "key")) | trim }}
  {{- $operator := include "base.string.normalize" (include "base.get" (list . "operator")) | trim }}
  {{- $value := include "base.string.normalize" (include "base.get" (list . "value")) | trim }}

  {{- /* 互斥校验: 三者至少一个有值时执行，全部校验先于任何字段输出完成。 */ -}}
  {{- if or $key $operator $value }}
    {{- /* key 为空时 operator 必须为 Exists。 */ -}}
    {{- if and (not $key) (ne $operator "Exists") }}
      {{- fail "[definitions.toleration] operator: must be Exists when key is empty" }}
    {{- end }}

    {{- /* operator 为 Exists 时 value 必须为空。 */ -}}
    {{- if and (eq $operator "Exists") $value }}
      {{- fail "[definitions.toleration] value: must be empty when operator is Exists" }}
    {{- end }}

    {{- /* operator 为 Gt 或 Lt 时 value 必须非空。 */ -}}
    {{- if and (or (eq $operator "Gt") (eq $operator "Lt")) (not $value) }}
      {{- fail (printf "[definitions.toleration] value: required when operator is %s" $operator) }}
    {{- end }}
  {{- end }}

  {{- /* effect（string, 可选）: 非空时按枚举校验并以带引号标量输出。 */ -}}
  {{- if $effect }}
    {{- include "base.field" (list "effect" $effect "quote" (list "NoExecute" "NoSchedule" "PreferNoSchedule")) }}
  {{- end }}

  {{- /* key（string, 可选）: 非空时以带引号标量输出。 */ -}}
  {{- if $key }}
    {{- include "base.field" (list "key" $key "quote") }}
  {{- end }}

  {{- /* operator（string, 可选）: 非空时按枚举校验并以带引号标量输出。 */ -}}
  {{- if $operator }}
    {{- include "base.field" (list "operator" $operator "quote" (list "Equal" "Exists" "Gt" "Lt")) }}
  {{- end }}

  {{- /* tolerationSeconds（integer, 可选）: 原始输出非空即生效，类型门禁与输出委托 base.int。 */ -}}
  {{- $_tolerationSecondsRaw := include "base.get" (list . "tolerationSeconds") | trim }}
  {{- if $_tolerationSecondsRaw }}
    {{- include "base.field" (list "tolerationSeconds" $_tolerationSecondsRaw "base.int") }}
  {{- end }}

  {{- /* value（string, 可选）: 非空时以带引号标量输出。 */ -}}
  {{- if $value }}
    {{- include "base.field" (list "value" $value "quote") }}
  {{- end }}
{{- end }}
