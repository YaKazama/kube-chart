{{- /*
  渲染 Kubernetes PersistentVolumeClaimVolumeSource 字段片段。

  行为 (按 K8s API 规范字段顺序):
    - claimName (string, 必填): 解码后 trim 判空，以带引号标量输出。
    - readOnly  (boolean, 可选): 剥离 YAML 引号并 trim；空值跳过，非空时按 boolean 校验并输出小写。

  边界:
    - 只输出当前层字段，不输出 persistentVolumeClaim 父键、apiVersion 或 kind；claimName 必输出。
    - 上下文可为原生 map 或父模板清洗后的 map，两种形态按同一契约渲染。
    - map 只读取 claimName 与 readOnly，未声明的键静默忽略；base.get 默认开启别名，因此 claimNameAlias、readOnlyAlias 隐式生效。
    - claimName 只接受 string 标量；非 string 标量由 base.string.normalize 中断，null 或空字符串按未提供处理。
    - readOnly 的类型校验由 base.bool 中断。
    - 本模板自身产生的失败消息使用 [definitions.persistentVolumeClaimVolumeSource] 前缀并带字段名；委托 base.* 时保留其自身前缀。

  入参: 上下文 map，可包含以下字段:
    - claimName (string, 必填)  同一命名空间内的 PersistentVolumeClaim 名称
    - readOnly  (boolean, 可选) 是否以只读权限挂载

  返回值: 可嵌入 Volume.persistentVolumeClaim 位置的 PersistentVolumeClaimVolumeSource YAML 字段片段。

  示例:
    {{- include "definitions.persistentVolumeClaimVolumeSource" (dict "claimName" "data") }}
      // claimName: "data"
    {{- include "definitions.persistentVolumeClaimVolumeSource" (dict "claimName" "data" "readOnly" true) }}
      // claimName: "data"
      // readOnly: true
*/ -}}
{{- define "definitions.persistentVolumeClaimVolumeSource" -}}
  {{- $const := include "base.env" "" | fromYaml }}

  {{- /* claimName（string, 必填）: 解码后 trim 判空，以带引号标量输出。 */ -}}
  {{- $claimName := include "base.string.normalize" (include "base.get" (list . "claimName")) | trim }}
  {{- if not $claimName }}
    {{- fail "[definitions.persistentVolumeClaimVolumeSource] claimName: required field is missing or empty" }}
  {{- end }}
  {{- include "base.field" (list "claimName" $claimName "quote") }}

  {{- /* readOnly（boolean, 可选）: 剥离 YAML 引号并 trim；空值跳过，非空时按 boolean 校验并输出小写。 */ -}}
  {{- $_readOnlyRaw := mustRegexReplaceAll $const.SYS.YAML_QUOTED (include "base.get" (list . "readOnly") | trim) "$1" | trim }}
  {{- if $_readOnlyRaw }}
    {{- include "base.field" (list "readOnly" (include "base.bool" (lower $_readOnlyRaw)) "base.bool") }}
  {{- end }}
{{- end }}
