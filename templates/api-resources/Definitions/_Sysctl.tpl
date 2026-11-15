{{- /*
  渲染 Kubernetes Sysctl 字段片段。

  行为 (按 K8s API 规范字段顺序):
    - name  (string, 必填): 归一后恒以带引号标量输出。
    - value (string, 必填): 归一后仅在会被 YAML 解析为非 string 时以带引号标量输出，否则原样输出。

  边界:
    - 只输出当前层字段，不输出 sysctls 父键、apiVersion 或 kind；两字段必填，模板恒有输出。
    - 同级 nameAlias、valueAlias 由 base.get 隐式识别并优先于规范键，属合法输入；除字段及其同级别名以外的入参字段静默忽略。
    - name 缺失、为 null、为空字符串或只含空白时中断。
    - value 在 value 与 valueAlias 均未提供时中断；两者仅提供其一时视为已提供。
    - value 为 null、空字符串或只含空白时视为空值，输出 value: ""，不中断。
    - value 取字符串 "null" 时为普通取值，输出 value: "null"，与 null 不同。
    - 两个字段取值均先 trim，判空、引号判定与输出均使用 trim 后的结果。
    - 两个字段不是 string 时中断，不做类型归一化；数字、布尔、map 与 array 均视为非法。
    - 输出取值不做任何改写：形如 007、0000 的取值原样保留，不折叠前导零。
    - 引号决策依据取值自身的 YAML 回读类型，因此 0、8080、true、on、1.5 与 007 等字面量都会被加引号。

  入参: 上下文 map，恒含以下字段:
    - name  (string, 必填) 内核参数名，可写作同级 nameAlias
    - value (string, 必填) 内核参数值，可写作同级 valueAlias；允许空字符串与 null

  返回值: 可嵌入 sysctls 元素下的 Sysctl YAML 字段片段。

  示例:
    {{- include "definitions.sysctl" (dict "name" "net.ipv4.ip_forward" "value" "1") }}  // name: "net.ipv4.ip_forward"
                                                                                         // value: "1"
*/ -}}
{{- define "definitions.sysctl" -}}
  {{- /* name（string, 必填）: 经 base.get 取值与别名识别、base.string.normalize 解码后 trim，为空则中断；恒以带引号标量输出。 */ -}}
  {{- $name := include "base.string.normalize" (include "base.get" (list . "name")) | trim }}
  {{- if not $name }}
    {{- fail "[definitions.sysctl] name: required field is missing or empty" }}
  {{- end }}
  {{- include "base.field" (list "name" (quote $name) "base.rawString") }}

  {{- /* value（string, 必填）: value 与 valueAlias 均未提供时中断；null、空串与纯空白归一为空值并输出 ""。 */ -}}
  {{- if not (or (hasKey . "value") (hasKey . "valueAlias")) }}
    {{- fail "[definitions.sysctl] value: required field is missing" }}
  {{- end }}
  {{- $value := include "base.string.normalize" (include "base.get" (list . "value")) | trim }}
  {{- /* 回读一次即可覆盖数字、布尔、null 与前导零等全部需要引号的字面量；空值回读为 null，同样落入加引号分支。 */ -}}
  {{- $needsQuote := not (kindIs "string" (fromYaml (printf "v: %s" $value)).v) }}
  {{- include "base.field" (list "value" (ternary (quote $value) $value $needsQuote) "base.rawString") }}
{{- end }}
