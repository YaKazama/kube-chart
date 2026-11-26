{{- /*
  渲染 Kubernetes PersistentVolumeClaimSpec 字段片段。

  行为 (按 K8s API 规范字段顺序):
    - accessModes (string array, 可选): 元素必须为 string，去除首尾空白后按官方枚举校验；空数组不输出。
    - dataSource (TypedLocalObjectReference, 可选): 非空 map 委托 definitions.typedLocalObjectReference 渲染。
    - dataSourceRef (TypedObjectReference, 可选): 非空 map 委托 definitions.typedObjectReference 渲染。
    - resources (VolumeResourceRequirements, 可选): 非空 map 委托 definitions.volumeResourceRequirements 渲染。
    - selector (LabelSelector, 可选): 非空 map 委托 definitions.labelSelector 渲染。
    - storageClassName (string, 可选): 去除首尾空白后非空时输出。
    - volumeAttributesClassName (string, 可选): 去除首尾空白后非空时输出。
    - volumeMode (string, 可选): 去除首尾空白后按官方枚举校验并输出。
    - volumeName (string, 可选): 去除首尾空白后非空时输出。

  边界:
    - 所有字段可选；全部无有效输出时本模板输出空内容，不输出 spec 父键、status、apiVersion 或 kind。
    - 只识别上述九个规范键；其他入参字段静默忽略。
    - definitions.typedLocalObjectReference、definitions.typedObjectReference 与 definitions.volumeResourceRequirements 当前不可用且不在本 change 创建，只保留调用占位。
    - definitions.labelSelector 已存在，其内部字段与校验边界由该模板决定。
    - 本模板自身产生的失败消息使用 [core.persistentVolumeClaimSpec] 前缀；委托 base.* 与子模板时保留其自身前缀。

  入参: 上下文 map，可包含以下字段:
    - accessModes               (string array, 可选)
    - dataSource                (TypedLocalObjectReference, 可选)
    - dataSourceRef             (TypedObjectReference, 可选)
    - resources                 (VolumeResourceRequirements, 可选)
    - selector                  (LabelSelector, 可选)
    - storageClassName          (string, 可选)
    - volumeAttributesClassName (string, 可选)
    - volumeMode                (string, 可选)
    - volumeName                (string, 可选)

  返回值: 可嵌入 spec 下的 PersistentVolumeClaimSpec YAML 字段片段；无有效内容时为空。

  示例:
    {{- include "core.persistentVolumeClaimSpec" (dict "accessModes" (list "ReadWriteOnce")) }}
      // accessModes:
      // - ReadWriteOnce
*/ -}}
{{- define "core.persistentVolumeClaimSpec" -}}
  {{- /* accessModes（string array, 可选）: 逐项校验 string 类型、去空白与官方枚举，按输入顺序输出。 */ -}}
  {{- $_accessModesRaw := include "base.get" (list . "accessModes") | trim }}
  {{- if $_accessModesRaw }}
    {{- $_accessModesParsed := $_accessModesRaw | fromYamlArray }}
    {{- if eq (include "base.isFromYamlArrayError" $_accessModesParsed) "true" }}
      {{- fail "[core.persistentVolumeClaimSpec] accessModes: must be array type" }}
    {{- end }}

    {{- $accessModes := list }}
    {{- range $_index, $_mode := $_accessModesParsed }}
      {{- if not (kindIs "string" $_mode) }}
        {{- fail (printf "[core.persistentVolumeClaimSpec] accessModes[%d]: must be string type" $_index) }}
      {{- end }}
      {{- $_modeValue := trim $_mode }}
      {{- if not (mustHas $_modeValue (list "ReadWriteOnce" "ReadOnlyMany" "ReadWriteMany" "ReadWriteOncePod")) }}
        {{- fail (printf "[core.persistentVolumeClaimSpec] accessModes[%d]: must be one of ReadWriteOnce, ReadOnlyMany, ReadWriteMany, ReadWriteOncePod" $_index) }}
      {{- end }}
      {{- $accessModes = mustAppend $accessModes $_modeValue }}
    {{- end }}

    {{- if $accessModes }}
      {{- include "base.field" (list "accessModes" $accessModes "base.slice") }}
    {{- end }}
  {{- end }}

  {{- /* dataSource（TypedLocalObjectReference, 可选）: 非空 map 原样委托 definitions.typedLocalObjectReference。 */ -}}
  {{- $_dataSourceRaw := include "base.get" (list . "dataSource") | trim }}
  {{- if $_dataSourceRaw }}
    {{- $_dataSource := $_dataSourceRaw | fromYaml }}
    {{- if eq (include "base.isFromYamlError" $_dataSource) "true" }}
      {{- fail "[core.persistentVolumeClaimSpec] dataSource: must be map type" }}
    {{- end }}
    {{- if not (kindIs "map" $_dataSource) }}
      {{- fail "[core.persistentVolumeClaimSpec] dataSource: must be map type" }}
    {{- end }}
    {{- if $_dataSource }}
      {{- $_dataSourceRendered := include "definitions.typedLocalObjectReference" $_dataSource | fromYaml }}
      {{- if eq (include "base.isFromYamlError" $_dataSourceRendered) "true" }}
        {{- fail "[core.persistentVolumeClaimSpec] dataSource: definitions.typedLocalObjectReference returned invalid YAML" }}
      {{- end }}
      {{- if $_dataSourceRendered }}
        {{- include "base.field" (list "dataSource" $_dataSourceRendered "base.map") }}
      {{- end }}
    {{- end }}
  {{- end }}

  {{- /* dataSourceRef（TypedObjectReference, 可选）: 非空 map 原样委托 definitions.typedObjectReference。 */ -}}
  {{- $_dataSourceRefRaw := include "base.get" (list . "dataSourceRef") | trim }}
  {{- if $_dataSourceRefRaw }}
    {{- $_dataSourceRef := $_dataSourceRefRaw | fromYaml }}
    {{- if eq (include "base.isFromYamlError" $_dataSourceRef) "true" }}
      {{- fail "[core.persistentVolumeClaimSpec] dataSourceRef: must be map type" }}
    {{- end }}
    {{- if not (kindIs "map" $_dataSourceRef) }}
      {{- fail "[core.persistentVolumeClaimSpec] dataSourceRef: must be map type" }}
    {{- end }}
    {{- if $_dataSourceRef }}
      {{- $_dataSourceRefRendered := include "definitions.typedObjectReference" $_dataSourceRef | fromYaml }}
      {{- if eq (include "base.isFromYamlError" $_dataSourceRefRendered) "true" }}
        {{- fail "[core.persistentVolumeClaimSpec] dataSourceRef: definitions.typedObjectReference returned invalid YAML" }}
      {{- end }}
      {{- if $_dataSourceRefRendered }}
        {{- include "base.field" (list "dataSourceRef" $_dataSourceRefRendered "base.map") }}
      {{- end }}
    {{- end }}
  {{- end }}

  {{- /* resources（VolumeResourceRequirements, 可选）: 非空 map 原样委托 definitions.volumeResourceRequirements。 */ -}}
  {{- $_resourcesRaw := include "base.get" (list . "resources") | trim }}
  {{- if $_resourcesRaw }}
    {{- $_resources := $_resourcesRaw | fromYaml }}
    {{- if eq (include "base.isFromYamlError" $_resources) "true" }}
      {{- fail "[core.persistentVolumeClaimSpec] resources: must be map type" }}
    {{- end }}
    {{- if not (kindIs "map" $_resources) }}
      {{- fail "[core.persistentVolumeClaimSpec] resources: must be map type" }}
    {{- end }}
    {{- if $_resources }}
      {{- $_resourcesRendered := include "definitions.volumeResourceRequirements" $_resources | fromYaml }}
      {{- if eq (include "base.isFromYamlError" $_resourcesRendered) "true" }}
        {{- fail "[core.persistentVolumeClaimSpec] resources: definitions.volumeResourceRequirements returned invalid YAML" }}
      {{- end }}
      {{- if $_resourcesRendered }}
        {{- include "base.field" (list "resources" $_resourcesRendered "base.map") }}
      {{- end }}
    {{- end }}
  {{- end }}

  {{- /* selector（LabelSelector, 可选）: 非空 map 原样委托 definitions.labelSelector。 */ -}}
  {{- $_selectorRaw := include "base.get" (list . "selector") | trim }}
  {{- if $_selectorRaw }}
    {{- $_selector := $_selectorRaw | fromYaml }}
    {{- if eq (include "base.isFromYamlError" $_selector) "true" }}
      {{- fail "[core.persistentVolumeClaimSpec] selector: must be map type" }}
    {{- end }}
    {{- if not (kindIs "map" $_selector) }}
      {{- fail "[core.persistentVolumeClaimSpec] selector: must be map type" }}
    {{- end }}
    {{- if $_selector }}
      {{- $_selectorRendered := include "definitions.labelSelector" $_selector | fromYaml }}
      {{- if eq (include "base.isFromYamlError" $_selectorRendered) "true" }}
        {{- fail "[core.persistentVolumeClaimSpec] selector: definitions.labelSelector returned invalid YAML" }}
      {{- end }}
      {{- if $_selectorRendered }}
        {{- include "base.field" (list "selector" $_selectorRendered "base.map") }}
      {{- end }}
    {{- end }}
  {{- end }}

  {{- /* storageClassName（string, 可选）: 去除首尾空白后非空时输出。 */ -}}
  {{- $storageClassName := include "base.string.normalize" (include "base.get" (list . "storageClassName")) | trim }}
  {{- if $storageClassName }}
    {{- include "base.field" (list "storageClassName" $storageClassName) }}
  {{- end }}

  {{- /* volumeAttributesClassName（string, 可选）: 去除首尾空白后非空时输出。 */ -}}
  {{- $volumeAttributesClassName := include "base.string.normalize" (include "base.get" (list . "volumeAttributesClassName")) | trim }}
  {{- if $volumeAttributesClassName }}
    {{- include "base.field" (list "volumeAttributesClassName" $volumeAttributesClassName) }}
  {{- end }}

  {{- /* volumeMode（string, 可选）: 去除首尾空白后按官方枚举 Filesystem、Block 校验并输出。 */ -}}
  {{- $volumeMode := include "base.string.normalize" (include "base.get" (list . "volumeMode")) | trim }}
  {{- if $volumeMode }}
    {{- include "base.field" (list "volumeMode" $volumeMode "base.string" (list "Filesystem" "Block")) }}
  {{- end }}

  {{- /* volumeName（string, 可选）: 去除首尾空白后非空时输出。 */ -}}
  {{- $volumeName := include "base.string.normalize" (include "base.get" (list . "volumeName")) | trim }}
  {{- if $volumeName }}
    {{- include "base.field" (list "volumeName" $volumeName) }}
  {{- end }}
{{- end }}
