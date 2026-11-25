{{- /*
  渲染 Kubernetes PersistentVolumeClaimTemplate 字段片段。

  行为 (按 K8s API 规范字段顺序):
    - metadata (ObjectMeta, 可选): 经 base.get 取值并恢复为 map，缺失、null 或空 map 时省略；非空时直接委托 definitions.objectMeta 渲染，不设置 _kind 或 _pkind。
    - spec (PersistentVolumeClaimSpec, 必填): 经 base.get 取值并恢复为 map，缺失、null 或空 map 时中断；委托 core.persistentVolumeClaimSpec 渲染，子模板返回空内容或非法 YAML 时中断。

  边界:
    - 只读取 metadata 与 spec，其他入参字段静默忽略；不输出 volumeClaimTemplate 父键、apiVersion、kind、status 或控制字段。
    - base.get 默认开启别名识别，metadataAlias 与 specAlias 隐式生效。
    - metadata 与 spec 均先恢复并检查解析错误；可解析为 map 的字符串按 map 处理。
    - definitions.objectMeta 已实现，直接以 metadata map 调用；metadata 的字段范围、默认值与失败由该模板决定。
    - core.persistentVolumeClaimSpec 当前不可用且不在本 change 创建；调用契约已固定，真实渲染需该子模板或隔离 fixture 提供定义。
    - 本模板自身产生的失败消息使用 [definitions.persistentVolumeClaimTemplate] 前缀；委托子模板时保留其自身前缀。

  入参: 上下文 map，可包含以下字段:
    - metadata (ObjectMeta, 可选)                 PVC 模板的元数据
    - spec     (PersistentVolumeClaimSpec, 必填) PVC 模板的规格

  返回值: 可嵌入 volumeClaimTemplate 下的 PersistentVolumeClaimTemplate YAML 字段片段。

  示例:
    {{- include "definitions.persistentVolumeClaimTemplate" (dict "spec" (dict "accessModes" (list "ReadWriteOnce"))) }}
      // spec: ...
*/ -}}
{{- define "definitions.persistentVolumeClaimTemplate" -}}
  {{- /* 入参类型: 只接受 map，其他类型中断。 */ -}}
  {{- if not (kindIs "map" .) }}
    {{- fail (printf "[definitions.persistentVolumeClaimTemplate] context: expected map type, got '%v' (kind: %s)" . (kindOf .)) }}
  {{- end }}

  {{- /* metadata（ObjectMeta, 可选）: 恢复为 map，非空时直接委托 definitions.objectMeta 渲染，子模板无有效输出时省略。 */ -}}
  {{- $_metadataRaw := include "base.get" (list . "metadata") }}
  {{- $metadata := $_metadataRaw | fromYaml }}
  {{- if eq (include "base.isFromYamlError" $metadata) "true" }}
    {{- fail "[definitions.persistentVolumeClaimTemplate] metadata: must be map type" }}
  {{- end }}
  {{- if $metadata }}
    {{- $_metadataRendered := include "definitions.objectMeta" $metadata | fromYaml }}
    {{- if eq (include "base.isFromYamlError" $_metadataRendered) "true" }}
      {{- fail "[definitions.persistentVolumeClaimTemplate] metadata: definitions.objectMeta returned invalid YAML" }}
    {{- end }}
    {{- if $_metadataRendered }}
      {{- include "base.field" (list "metadata" $_metadataRendered "base.map") }}
    {{- end }}
  {{- end }}

  {{- /* spec（PersistentVolumeClaimSpec, 必填）: 缺失或为空时中断，否则委托 core.persistentVolumeClaimSpec 并校验渲染结果。 */ -}}
  {{- $_specRaw := include "base.get" (list . "spec") }}
  {{- $spec := $_specRaw | fromYaml }}
  {{- if eq (include "base.isFromYamlError" $spec) "true" }}
    {{- fail "[definitions.persistentVolumeClaimTemplate] spec: must be map type" }}
  {{- end }}
  {{- if not $spec }}
    {{- fail "[definitions.persistentVolumeClaimTemplate] spec: required field is missing or empty" }}
  {{- end }}
  {{- $_specRendered := include "core.persistentVolumeClaimSpec" $spec | fromYaml }}
  {{- if eq (include "base.isFromYamlError" $_specRendered) "true" }}
    {{- fail "[definitions.persistentVolumeClaimTemplate] spec: core.persistentVolumeClaimSpec returned invalid YAML" }}
  {{- end }}
  {{- if not $_specRendered }}
    {{- fail "[definitions.persistentVolumeClaimTemplate] spec: core.persistentVolumeClaimSpec returned empty output" }}
  {{- end }}
  {{- include "base.field" (list "spec" $_specRendered "base.map") }}
{{- end }}
