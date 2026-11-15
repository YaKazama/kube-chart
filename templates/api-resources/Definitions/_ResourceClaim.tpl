{{- /*
  渲染 Kubernetes ResourceClaim 字段片段。

  行为 (按 K8s API 规范字段顺序):
    - name (string, 必填): 经 base.get 必填取值并按 YAML 标量语义解码；解码后为空或仅空白时中断，非空时以带引号标量输出。
    - request (string, 可选): 同 name 的取值与解码方式；解码后为空时视为未设置。

  边界:
    - 只输出 name 与 request，不包含父级键；resourceClaims 数组的循环、字符串简写拆分、条目合并与去重由调用方负责。
    - 入参已由父级清洗；除 name、request 以外的键静默忽略，不透传到输出。
    - 关闭 base.get 的别名识别，因此 nameAlias、requestAlias 不参与取值。
    - name 缺失、为 null 或空字符串时由 base.get 必填校验中断；解码后为空时以本模板前缀中断。
    - 任一字段不是 string 时由 base.string.normalize 中断，失败消息使用其自身前缀。
    - 不校验 name 的名称格式；不输出 status、apiVersion、kind。

  入参: 上下文 map，由父级传入单个资源声明描述，可包含以下字段:
    - name    (string, 必填) 容器内使用的资源声明名称
    - request (string, 可选) 引用的 claim 中的请求名称

  返回值: 可嵌入 resources.claims 数组元素的 ResourceClaim YAML 字段片段，恒含 name。

  示例:
    {{- include "definitions.resourceClaim" (dict "name" "gpu" "request" "shared") }}
*/ -}}
{{- define "definitions.resourceClaim" -}}
  {{- /* name（string, 必填）: base.get 承担必填取值，base.string.normalize 按 YAML 标量语义解码并 trim，仅空白等同未设置；校验通过后立即渲染。 */ -}}
  {{- $_name := include "base.string.normalize" (include "base.get" (list . "name" "" "" true false)) | trim }}
  {{- if not $_name }}
    {{- fail "[definitions.resourceClaim] name: required field must not be blank" }}
  {{- end }}
  {{- include "base.field" (list "name" $_name "quote") }}

  {{- /* request（string, 可选）: 同 name 的取值与解码方式，解码后为空时视为未设置，非空时立即渲染。 */ -}}
  {{- $_request := include "base.string.normalize" (include "base.get" (list . "request" "" "" false false)) | trim }}
  {{- if $_request }}
    {{- include "base.field" (list "request" $_request "quote") }}
  {{- end }}
{{- end }}
