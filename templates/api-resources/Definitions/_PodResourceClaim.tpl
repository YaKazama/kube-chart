{{- /*
  渲染 Kubernetes PodResourceClaim 字段片段。

  行为 (按 K8s API 规范字段顺序):
    - name (string, 必填): 经 base.get 必填取值并按 YAML 标量语义解码；为空或仅空白时中断，非空时以带引号标量输出。
    - resourceClaimName (string, 可选): 同 name 的取值与解码方式；解码后为空时视为未设置。
    - resourceClaimTemplateName (string, 可选): 同 resourceClaimName。
    - 两个引用字段恰有一个生效：二者同时未设置或同时设置时中断。

  边界:
    - 只输出 name 与恰一个引用字段，不包含父级键；resourceClaims 数组的循环、字符串简写拆分、条目合并与去重由调用方负责。
    - base.get 默认开启别名识别，因此 nameAlias、resourceClaimNameAlias、resourceClaimTemplateNameAlias 隐式生效，本模板不额外实现别名映射。
    - name 缺失、为 null 或空字符串时由 base.get 必填校验中断；解码后为空时以本模板前缀中断。
    - 任一字段不是 string 时由 base.string.normalize 中断，失败消息使用其自身前缀；引用字段解码后为空时按未设置处理。
    - 不校验引用字段的名称格式；除三个字段及其同级别名以外的入参字段静默忽略；不输出 status、apiVersion、kind。

  入参: 上下文 map，由父级传入单个 resourceClaim 描述，可包含以下字段:
    - name                      (string, 必填) 该资源声明在 Pod 内的唯一名称
    - resourceClaimName         (string, 可选) 同命名空间内的 ResourceClaim 名称
    - resourceClaimTemplateName (string, 可选) 同命名空间内的 ResourceClaimTemplate 名称

  返回值: 可嵌入 resourceClaims 数组元素的 PodResourceClaim YAML 字段片段，恒含 name 与恰一个引用字段。

  示例:
    {{- include "definitions.podResourceClaim" (dict "name" "gpu" "resourceClaimName" "shared-gpu") }}
*/ -}}
{{- define "definitions.podResourceClaim" -}}
  {{- /* name（string, 必填）: base.get 承担必填取值与别名识别，base.string.normalize 按 YAML 标量语义解码并 trim，仅空白等同未设置。 */ -}}
  {{- $name := include "base.string.normalize" (include "base.get" (list . "name" "" "" true)) | trim }}
  {{- if not $name }}
    {{- fail "[definitions.podResourceClaim] name: required field must not be blank" }}
  {{- end }}

  {{- /* resourceClaimName（string, 可选）: 同 name 的取值与解码方式，解码后为空时视为未设置。 */ -}}
  {{- $resourceClaimName := include "base.string.normalize" (include "base.get" (list . "resourceClaimName")) | trim }}

  {{- /* resourceClaimTemplateName（string, 可选）: 同 resourceClaimName。 */ -}}
  {{- $resourceClaimTemplateName := include "base.string.normalize" (include "base.get" (list . "resourceClaimTemplateName")) | trim }}

  {{- /* 两个引用字段恰有一个生效: 归一化为空视为未设置，两者同时未设置或同时设置均中断。 */ -}}
  {{- if ne (len (mustCompact (list $resourceClaimName $resourceClaimTemplateName))) 1 }}
    {{- fail "[definitions.podResourceClaim] resourceClaimName/resourceClaimTemplateName: exactly one must be set" }}
  {{- end }}

  {{- /* 输出按 API 字段顺序: name 必填，引用字段由上面的互斥判定保证恰有一个非空。 */ -}}
  {{- include "base.field" (list "name" $name "quote") }}
  {{- if $resourceClaimName }}
    {{- include "base.field" (list "resourceClaimName" $resourceClaimName "quote") }}
  {{- else }}
    {{- include "base.field" (list "resourceClaimTemplateName" $resourceClaimTemplateName "quote") }}
  {{- end }}
{{- end }}
