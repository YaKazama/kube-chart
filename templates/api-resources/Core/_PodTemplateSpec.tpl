{{- /*
  渲染 Kubernetes PodTemplateSpec 资源。参考 https://kubernetes.io/docs/reference/kubernetes-api/core/pod-template-v1/#PodTemplateSpec

  行为（按 K8s API 规范字段顺序）:
    - metadata（object, 可选）: 委托 definitions.objectMeta 渲染，直接透传上下文 (.)。调用方需保证 . 中设置 _kind=PodTemplateSpec（或 _pkind=PodTemplateSpec），下层据此自动跳过 annotations / name / namespace 等不适用的元数据字段。渲染结果缺失 / 为空时不输出该字段。
    - spec（object, 必填）: 委托 core.podSpec 渲染，直接透传上下文 (.)。必填校验由 core.podSpec 与上层 apps.deploymentSpec 收口，本模板不对 spec 缺失做重复 fail。
    - 不渲染 status 字段。

  入参: 上下文 map，由上层 apps.deploymentSpec 透传（调用方需保证 metadata / spec 字段位于 . 顶层）。
    - metadata    (object, 可选)   ObjectMeta 结构（仅 labels 等可选字段）
    - spec        (object, 必填)   PodSpec 结构

  返回值: PodTemplateSpec 资源 YAML 键值对（不含顶级 "---"，由调用方决定）

  示例:
    {{- include "core.podTemplateSpec" . }}
*/ -}}
{{- define "core.podTemplateSpec" -}}
  {{- /* Step 1: metadata（object, 可选）: 委托 definitions.objectMeta 渲染
       直接透传上下文 (.), 调用方需保证 . 中设置 _kind=PodTemplateSpec 以驱动 metadata 字段过滤
       渲染结果缺失 / 为空时不输出该字段, 符合"非必填字段缺省"边界行为
       兼容 Helm 4.2.2 fromYaml 对非 map 输入返回错误 map 的 BUG, 委托 base.isFromYamlError 检测 */ -}}
  {{- $metadata := include "definitions.objectMeta" . | fromYaml }}
  {{- if $metadata }}
    {{- if eq (include "base.isFromYamlError" $metadata) "true" }}
      {{- fail "[core.podTemplateSpec] metadata: invalid YAML output from definitions.objectMeta" }}
    {{- end }}
    {{- if not (kindIs "map" $metadata) }}
      {{- fail "[core.podTemplateSpec] metadata: must be map type" }}
    {{- end }}
    {{- include "base.field" (list "metadata" $metadata "base.map") }}
  {{- end }}

  {{- /* Step 2: spec（object, 必填）: 委托 core.podSpec 渲染
       直接透传上下文 (.), 必填校验由 core.podSpec 与上层 apps.deploymentSpec 收口
       本模板不对 spec 缺失做重复 fail, 由 apps.deploymentSpec 的 template 必填校验统一收口
       兼容 Helm 4.2.2 fromYaml 对非 map 输入返回错误 map 的 BUG, 委托 base.isFromYamlError 检测 */ -}}
  {{- $spec := include "core.podSpec" . | fromYaml }}
  {{- if $spec }}
    {{- if eq (include "base.isFromYamlError" $spec) "true" }}
      {{- fail "[core.podTemplateSpec] spec: invalid YAML output from core.podSpec" }}
    {{- end }}
    {{- if not (kindIs "map" $spec) }}
      {{- fail "[core.podTemplateSpec] spec: must be map type" }}
    {{- end }}
    {{- include "base.field" (list "spec" $spec "base.map") }}
  {{- end }}
{{- end -}}
