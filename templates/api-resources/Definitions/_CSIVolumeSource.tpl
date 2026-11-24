{{- /*
  渲染 Kubernetes CSIVolumeSource 字段片段。

  行为 (按 K8s API 规范字段顺序):
    - driver               (string, 必填): 经 base.get 取值并按 YAML 标量语义解码，trim 后判空；非空时以带引号标量输出。
    - fsType               (string, 可选): 空值跳过；非空时由 base.field 的允许值列表校验 ext4、xfs、ntfs 并原样输出。
    - nodePublishSecretRef (LocalObjectReference 或 string, 可选): string 形态表示 secret 名称，剥离 YAML 引号并 trim 后为空则跳过，非空时组装为 name 上下文；map 形态原样透传；委托 definitions.localObjectReference 渲染，结果为空时跳过。
    - readOnly             (boolean, 可选): 剥离 YAML 引号并 trim 后为空则跳过，其余交 base.bool 校验并输出，显式 false 生效。
    - volumeAttributes     (object, 可选): 非空 map 输出，值必须为 string。

  边界:
    - 只输出当前层字段，不输出 csi 父键、apiVersion 或 kind；无有效内容时为空内容。
    - nodePublishSecretRef 直接从上下文同名键读取以区分 string 与 map，因此不参与 base.get 的 *Alias 识别；其余字段经 base.get 取值，同级 <字段>Alias 隐式生效。
    - nodePublishSecretRef 的 string 形态只剥离 YAML 引号与 trim，不按 YAML 标量解码，因此 true、false 等名称可作为 secret 名称原样下传。
    - 可选字段为 nil、空字符串或空 map 时不输出对应键；除上述字段以外的入参字段静默忽略；不输出 status。
    - 本模板自身产生的失败消息使用 [definitions.csiVolumeSource] 前缀并带字段名；委托 base.* 与 definitions.localObjectReference 时保留其自身前缀。
    - 委托子模板输出不是合法 YAML 时中断。

  入参: 上下文 map，可包含以下字段:
    - driver               (string, 必填)                        CSI 驱动名称
    - fsType               (string, 可选)                        文件系统类型，取值为 ext4、xfs、ntfs
    - nodePublishSecretRef (LocalObjectReference 或 string, 可选) 发布时引用的 Secret
    - readOnly             (boolean, 可选)                       是否只读挂载
    - volumeAttributes     (object, 可选)                        驱动私有属性，值为 string

  返回值: 可嵌入 Volume.csi 位置的 CSIVolumeSource YAML 字段片段；无有效内容时为空内容。

  示例:
    {{- include "definitions.csiVolumeSource" (dict "driver" "csi.example.com") }}
      // driver: "csi.example.com"
    {{- include "definitions.csiVolumeSource" (dict "driver" "csi.example.com" "fsType" "ext4" "nodePublishSecretRef" "regcred" "readOnly" false "volumeAttributes" (dict "mode" "0777")) }}
      // driver: "csi.example.com"
      // fsType: ext4
      // nodePublishSecretRef:
      //   name: "regcred"
      // readOnly: false
      // volumeAttributes:
      //   mode: "0777"
*/ -}}
{{- define "definitions.csiVolumeSource" -}}
  {{- $const := include "base.env" "" | fromYaml }}

  {{- /* driver（string, 必填）: 经 base.get 与 YAML 标量解码后 trim 判空；非空时以带引号标量输出。 */ -}}
  {{- $driver := include "base.string.normalize" (include "base.get" (list . "driver")) | trim }}
  {{- if not $driver }}
    {{- fail "[definitions.csiVolumeSource] driver: required field is missing or empty" }}
  {{- end }}
  {{- include "base.field" (list "driver" $driver "quote") }}

  {{- /* fsType（string, 可选）: 空值跳过；非空时由 base.field 的允许值列表校验 ext4、xfs、ntfs。 */ -}}
  {{- $fsType := include "base.string.normalize" (include "base.get" (list . "fsType")) | trim }}
  {{- if $fsType }}
    {{- include "base.field" (list "fsType" $fsType "base.string" (list "ext4" "xfs" "ntfs")) }}
  {{- end }}

  {{- /* nodePublishSecretRef（LocalObjectReference 或 string, 可选）: string 形态剥离 YAML 引号后作为 name 组装上下文，map 形态原样透传；委托子模板结果为空时跳过。 */ -}}
  {{- $_secretRefRaw := get . "nodePublishSecretRef" }}
  {{- $_secretRef := dict }}
  {{- if kindIs "string" $_secretRefRaw }}
    {{- $_secretName := mustRegexReplaceAll $const.SYS.YAML_QUOTED $_secretRefRaw "$1" | trim }}
    {{- if $_secretName }}
      {{- $_secretRef = dict "name" $_secretName }}
    {{- end }}

  {{- else if kindIs "map" $_secretRefRaw }}
    {{- $_secretRef = $_secretRefRaw }}

  {{- else if not (kindIs "invalid" $_secretRefRaw) }}
    {{- fail (printf "[definitions.csiVolumeSource] nodePublishSecretRef: must be object or string type, got '%s'" (kindOf $_secretRefRaw)) }}
  {{- end }}
  {{- if $_secretRef }}
    {{- $_secretRefRendered := include "definitions.localObjectReference" $_secretRef | fromYaml }}
    {{- if eq (include "base.isFromYamlError" $_secretRefRendered) "true" }}
      {{- fail "[definitions.csiVolumeSource] nodePublishSecretRef: definitions.localObjectReference rendered invalid YAML" }}
    {{- end }}
    {{- if $_secretRefRendered }}
      {{- include "base.field" (list "nodePublishSecretRef" $_secretRefRendered "base.map") }}
    {{- end }}
  {{- end }}

  {{- /* readOnly（boolean, 可选）: 剥离 YAML 引号并 trim 后为空则跳过，其余交 base.bool 校验并输出，显式 false 生效。 */ -}}
  {{- $_readOnly := mustRegexReplaceAll $const.SYS.YAML_QUOTED (include "base.get" (list . "readOnly") | trim) "$1" | trim }}
  {{- if $_readOnly }}
    {{- include "base.field" (list "readOnly" $_readOnly "base.bool") }}
  {{- end }}

  {{- /* volumeAttributes（object, 可选）: 非空 map 输出，值必须为 string。 */ -}}
  {{- $_volumeAttributesRaw := include "base.get" (list . "volumeAttributes") | trim }}
  {{- if $_volumeAttributesRaw }}
    {{- $_volumeAttributes := $_volumeAttributesRaw | fromYaml }}
    {{- if eq (include "base.isFromYamlError" $_volumeAttributes) "true" }}
      {{- fail "[definitions.csiVolumeSource] volumeAttributes: must be object type" }}
    {{- end }}
    {{- range $key, $value := $_volumeAttributes }}
      {{- if not (kindIs "string" $value) }}
        {{- fail (printf "[definitions.csiVolumeSource] volumeAttributes.%s: expected string type, got '%s'" $key (kindOf $value)) }}
      {{- end }}
    {{- end }}
    {{- if $_volumeAttributes }}
      {{- include "base.field" (list "volumeAttributes" $_volumeAttributes "base.map") }}
    {{- end }}
  {{- end }}
{{- end }}
