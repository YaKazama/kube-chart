{{- /*
  渲染 Kubernetes AppArmorProfile 字段片段。

  行为 (按 K8s API 规范字段顺序):
    - localhostProfile (string, 可选): 仅在 type 为 Localhost 时处理；非空时以带引号标量输出，缺失或为空中断。
    - type (string, 必填): 去除首尾空白后按 Localhost、RuntimeDefault、Unconfined 枚举校验并输出。

  边界:
    - 只输出当前层字段，不输出 appArmorProfile 父键、apiVersion 或 kind；type 必填，模板恒有输出。
    - type 缺失、为 null、为空字符串或只含空白时中断；枚举比较大小写敏感。
    - type 非 string 时由 base.string.normalize 中断；为 string 但不在枚举内时由 base.field 中断并给出合法范围。
    - type 不是 Localhost 时完全不读取 localhostProfile：既不输出，也不因该字段缺失或类型非法而失败。
    - localhostProfile 不是 string 时由 base.string.normalize 中断，不做类型归一化。
    - base.get 默认开启别名识别，因此同级 typeAlias、localhostProfileAlias 隐式生效。
    - 除 localhostProfile、type 及其同级别名以外的入参字段静默忽略；不输出 status。

  入参: 上下文 map，可包含以下字段:
    - localhostProfile (string, 可选) 节点上预加载的 AppArmor profile 名
    - type             (string, 必填) AppArmor 配置类型

  返回值: 可嵌入 appArmorProfile 下的 AppArmorProfile YAML 字段片段。

  示例:
    {{- include "definitions.appArmorProfile" (dict "type" "RuntimeDefault") }}                  // type: RuntimeDefault
    {{- include "definitions.appArmorProfile" (dict "type" "Localhost" "localhostProfile" "p") }}  // localhostProfile: "p"
                                                                                                   // type: Localhost
*/ -}}
{{- define "definitions.appArmorProfile" -}}
  {{- /* type（string, 必填）: 经 base.string.normalize 解码并 trim，供空值判定、条件渲染与枚举校验共用。 */ -}}
  {{- $type := include "base.string.normalize" (include "base.get" (list . "type")) | trim }}
  {{- if not $type }}
    {{- fail "[definitions.appArmorProfile] type: required field is missing or empty" }}
  {{- end }}

  {{- /* localhostProfile（string, 可选）: 仅在 type 为 Localhost 时取值；归一后为空中断，非空时以带引号标量输出。 */ -}}
  {{- if eq $type "Localhost" }}
    {{- $localhostProfile := include "base.string.normalize" (include "base.get" (list . "localhostProfile")) | trim }}
    {{- if not $localhostProfile }}
      {{- fail "[definitions.appArmorProfile] localhostProfile: required when type is Localhost" }}
    {{- end }}
    {{- include "base.field" (list "localhostProfile" $localhostProfile "quote") }}
  {{- end }}

  {{- /* type（string, 必填）: 由 base.field 完成枚举校验与输出，未命中时给出合法范围。 */ -}}
  {{- include "base.field" (list "type" $type "base.string" (list "Localhost" "RuntimeDefault" "Unconfined")) }}
{{- end }}
