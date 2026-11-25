{{- /*
  渲染 Kubernetes EphemeralVolumeSource 字段片段。

  行为 (按 K8s API 规范字段顺序):
    - volumeClaimTemplate (PersistentVolumeClaimTemplate, 必填): 经 base.get 取值并恢复为 map，缺失、null 或空 map 时中断；委托 definitions.persistentVolumeClaimTemplate 渲染，子模板返回空内容时不输出该字段。

  边界:
    - 只读取 volumeClaimTemplate，其他入参字段静默忽略；不输出 ephemeral 父键、apiVersion 或 kind。
    - base.get 默认开启别名识别，volumeClaimTemplateAlias 隐式生效。
    - 取值经 YAML 恢复后检查解析错误与空值；可解析为 map 的字符串按 map 处理。
    - definitions.persistentVolumeClaimTemplate 当前不可用且不在本 change 创建；调用契约已固定，真实渲染需该子模板或隔离 fixture 提供定义。
    - 子模板返回非法 YAML 时中断；返回空内容时不输出 volumeClaimTemplate。
    - 本模板自身产生的失败消息使用 [definitions.ephemeralVolumeSource] 前缀；委托子模板时保留其自身前缀。

  入参: 上下文 map，包含以下字段:
    - volumeClaimTemplate (PersistentVolumeClaimTemplate, 必填) 临时卷的 PVC 模板

  返回值: 可嵌入 Volume.ephemeral 位置的 EphemeralVolumeSource YAML 字段片段；子模板返回空内容时为空内容。

  示例:
    {{- include "definitions.ephemeralVolumeSource" (dict "volumeClaimTemplate" (dict "metadata" (dict "name" "data"))) }}
      // volumeClaimTemplate: ...（最终内容由 definitions.persistentVolumeClaimTemplate 决定）
*/ -}}
{{- define "definitions.ephemeralVolumeSource" -}}
  {{- /* volumeClaimTemplate（PersistentVolumeClaimTemplate, 必填）: 必填取值并恢复为 map 后委托 definitions.persistentVolumeClaimTemplate；子模板输出为空时跳过。 */ -}}
  {{- $_volumeClaimTemplateRaw := include "base.get" (list . "volumeClaimTemplate") | fromYaml }}
  {{- if eq (include "base.isFromYamlError" $_volumeClaimTemplateRaw) "true" }}
    {{- fail "[definitions.ephemeralVolumeSource] volumeClaimTemplate: must be map type" }}
  {{- end }}
  {{- if not $_volumeClaimTemplateRaw }}
    {{- fail "[definitions.ephemeralVolumeSource] volumeClaimTemplate: required field is missing or empty" }}
  {{- end }}
  {{- $_volumeClaimTemplateRendered := include "definitions.persistentVolumeClaimTemplate" $_volumeClaimTemplateRaw | fromYaml }}
  {{- if eq (include "base.isFromYamlError" $_volumeClaimTemplateRendered) "true" }}
    {{- fail "[definitions.ephemeralVolumeSource] volumeClaimTemplate: definitions.persistentVolumeClaimTemplate returned invalid YAML" }}
  {{- end }}
  {{- if $_volumeClaimTemplateRendered }}
    {{- include "base.field" (list "volumeClaimTemplate" $_volumeClaimTemplateRendered "base.map") }}
  {{- end }}
{{- end }}
