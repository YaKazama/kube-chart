{{- /*
  渲染 Kubernetes SeccompProfile 字段片段。

  行为 (按 K8s API 规范字段顺序):
    - localhostProfile (string, 条件必填): 仅在 type 为 Localhost 时处理；非空时以带引号标量输出，缺失或为空中断。
    - type             (string, 必填): 去除首尾空白后按 Localhost、RuntimeDefault、Unconfined 枚举校验并输出。

  边界:
    - 只输出当前层字段，不输出 seccompProfile 父键、apiVersion 或 kind；type 必填，模板恒有输出。
    - 两个字段取值均先 trim，判空、条件判断与输出均使用 trim 后的结果。
    - type 缺失、为 null、为空字符串或只含空白时中断。
    - 枚举校验由 base.field 的允许值列表完成，比较大小写敏感，未命中时给出合法取值。
    - type 非 string 时由 base.string.normalize 中断，不做类型归一化。
    - type 不是 Localhost 时完全不读取 localhostProfile：既不输出，也不因该字段缺失或类型非法而失败。
    - localhostProfile 不是 string 时由 base.string.normalize 中断，不做类型归一化。
    - 字段值统一以双引号输出，避免 on、yes、true 等文本在父级回收后被解析为布尔。
    - base.get 默认开启别名识别，因此同级 typeAlias、localhostProfileAlias 隐式生效。
    - 除 type、localhostProfile 及其同级别名以外的入参字段静默忽略；不输出 status。

  入参: 上下文 map，可包含以下字段:
    - localhostProfile (string, 条件必填) 节点上预加载的 seccomp profile 路径，type 为 Localhost 时必填
    - type             (string, 必填)     seccomp 配置类型

  返回值: 可嵌入 seccompProfile 下的 SeccompProfile YAML 字段片段。

  示例:
    {{- include "definitions.seccompProfile" (dict "type" "RuntimeDefault") }}                         // type: "RuntimeDefault"
    {{- include "definitions.seccompProfile" (dict "type" "Localhost" "localhostProfile" "p.json") }}  // localhostProfile: "p.json"
                                                                                                     // type: "Localhost"
*/ -}}
{{- define "definitions.seccompProfile" -}}
  {{- /* type（string, 必填）: 经 base.string.normalize 解码并 trim，供必填判空与 Localhost 分支判断共用，并作为枚举校验的输入。 */ -}}
  {{- $type := include "base.string.normalize" (include "base.get" (list . "type")) | trim }}
  {{- if not $type }}
    {{- fail "[definitions.seccompProfile] type: required field is missing or empty" }}
  {{- end }}

  {{- /* localhostProfile（string, 条件必填）: 仅在 type 为 Localhost 时取值；归一后为空中断，非空时以带引号标量输出。 */ -}}
  {{- if eq $type "Localhost" }}
    {{- $localhostProfile := include "base.string.normalize" (include "base.get" (list . "localhostProfile")) | trim }}
    {{- if not $localhostProfile }}
      {{- fail "[definitions.seccompProfile] localhostProfile: required when type is Localhost" }}
    {{- end }}
    {{- include "base.field" (list "localhostProfile" $localhostProfile "quote") }}
  {{- end }}

  {{- /* type（string, 必填）: 由 base.field 允许值列表完成枚举校验，并以带引号标量输出。 */ -}}
  {{- include "base.field" (list "type" $type "quote" (list "Localhost" "RuntimeDefault" "Unconfined")) }}
{{- end }}
