{{- /*
  渲染 Kubernetes PodTemplateSpec 字段片段。

  行为 (按 K8s API 规范字段顺序):
    - metadata (ObjectMeta, 可选): 委托 definitions.objectMeta 渲染，子模板无有效输出时省略该字段。
    - spec (PodSpec, 可选): 委托 core.podSpec 渲染，子模板无有效输出时省略该字段。

  边界:
    - 原地设置 _kind 为 PodTemplateSpec 并继续传递同一上下文；_pkind 不设置、不覆盖、不读取，随上下文原样透传。
    - 两个字段均不承担必填判断，空输出、无效 YAML 与无法恢复为 map 的内容只在调用侧省略，子模板自身失败原样向上传播。
    - 不输出 status、文档分隔符或 _kind、_pkind 等控制字段。

  入参: 上下文 map，包含 definitions.objectMeta 与 core.podSpec 所需字段。

  返回值: 包含 metadata 与 spec 的 PodTemplateSpec YAML 字段片段。

  示例:
    {{- include "core.podTemplateSpec" . }}
*/ -}}
{{- define "core.podTemplateSpec" -}}
  {{- $_ := set . "_kind" "PodTemplateSpec" -}}

  {{- /* metadata（ObjectMeta）：承载 Pod 模板对象元数据，委托 definitions.objectMeta 渲染，无有效输出时省略。 */ -}}
  {{- $metadata := include "definitions.objectMeta" . | fromYaml }}
  {{- if and (not (eq (include "base.isFromYamlError" $metadata) "true")) $metadata }}
    {{- include "base.field" (list "metadata" $metadata "base.map") }}
  {{- end }}

  {{- /* spec（PodSpec）：描述 Pod 的期望行为，委托 core.podSpec 渲染，无有效输出时省略。 */ -}}
  {{- $spec := include "core.podSpec" . | fromYaml }}
  {{- if and (not (eq (include "base.isFromYamlError" $spec) "true")) $spec }}
    {{- include "base.field" (list "spec" $spec "base.map") }}
  {{- end }}
{{- end }}
