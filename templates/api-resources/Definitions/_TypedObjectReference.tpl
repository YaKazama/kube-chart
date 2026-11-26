{{- /*
  渲染 Kubernetes TypedObjectReference 字段片段。

  行为 (按 K8s API 规范字段顺序):
    - apiGroup (string, 可选): 解码后非空时以带引号标量输出；缺省、空白或 null 时不输出，不补默认值，也不校验格式。
    - kind (string, 必填): 解码后判空，非空时以带引号标量输出，缺失或空白时中断。
    - name (string, 必填): 解码后判空，非空时以带引号标量输出，缺失或空白时中断。
    - namespace (string, 可选): 解码后非空时按 RFC1123 Label 校验并以带引号标量输出；缺省、空白或 null 时不输出，不补默认值。

  边界:
    - 只输出 apiGroup、kind、name 与 namespace，不包含父级键；父级引用的循环、合并与去重由调用方负责。
    - base.get 默认开启别名识别，因此同级 apiGroupAlias、kindAlias、nameAlias、namespaceAlias 隐式生效，本模板不额外实现别名映射。
    - apiGroup 不校验 API 组格式或注册状态，允许任意非空字符串。
    - namespace 的 RFC1123 Label 与 63 字符上限校验由 base.rfc 收口，失败消息保留其自身前缀。
    - kind 与 name 的类型错误由 base.string.normalize 中断，失败消息使用其自身前缀；缺失或空白由本模板以 [definitions.typedObjectReference] 前缀中断。
    - 除四个字段及其同级别名以外的入参字段静默忽略；不输出 status、apiVersion 或其他父级字段。

  入参: 上下文 map，可包含以下字段:
    - apiGroup  (string, 可选) 被引用资源所属的 API 组，缺省表示 core
    - kind      (string, 必填) 被引用资源的类型
    - name      (string, 必填) 被引用资源的名称
    - namespace (string, 可选) 被引用资源所在的命名空间

  返回值: 可嵌入 TypedObjectReference 位置的 YAML 字段片段，按 apiGroup、kind、name、namespace 顺序输出，恒含 kind 与 name。

  示例:
    {{- include "definitions.typedObjectReference" (dict "kind" "PersistentVolumeClaim" "name" "data") }}
    {{- include "definitions.typedObjectReference" (dict "apiGroup" "example.com" "kind" "MyResource" "name" "sample" "namespace" "backup") }}
*/ -}}
{{- define "definitions.typedObjectReference" -}}
  {{- /* apiGroup（string, 可选）: 解码后为空时跳过，不补默认值；非空时原样以带引号标量输出，不校验格式。 */ -}}
  {{- $apiGroup := include "base.string.normalize" (include "base.get" (list . "apiGroup")) | trim }}
  {{- if $apiGroup }}
    {{- include "base.field" (list "apiGroup" $apiGroup "quote") }}
  {{- end }}

  {{- /* kind（string, 必填）: 解码并 trim 后为空时中断，非空时以带引号标量输出。 */ -}}
  {{- $kind := include "base.string.normalize" (include "base.get" (list . "kind")) | trim }}
  {{- if not $kind }}
    {{- fail "[definitions.typedObjectReference] kind: required field is missing or empty" }}
  {{- end }}
  {{- include "base.field" (list "kind" $kind "quote") }}

  {{- /* name（string, 必填）: 解码并 trim 后为空时中断，非空时以带引号标量输出。 */ -}}
  {{- $name := include "base.string.normalize" (include "base.get" (list . "name")) | trim }}
  {{- if not $name }}
    {{- fail "[definitions.typedObjectReference] name: required field is missing or empty" }}
  {{- end }}
  {{- include "base.field" (list "name" $name "quote") }}

  {{- /* namespace（string, 可选）: 解码后为空时跳过，不补默认值；非空时按 RFC1123 Label 校验后以带引号标量输出。 */ -}}
  {{- $namespace := include "base.string.normalize" (include "base.get" (list . "namespace")) | trim }}
  {{- if $namespace }}
    {{- include "base.field" (list "namespace" (include "base.rfc" (list $namespace "1123")) "quote") }}
  {{- end }}
{{- end }}
