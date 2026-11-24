{{- /*
  渲染 Kubernetes EmptyDirVolumeSource 字段片段。

  行为 (按 K8s API 规范字段顺序):
    - medium    (string, 可选): YAML 标量解码后 trim；仅 Memory 合法，空值跳过，其他值中断。
    - sizeLimit (Quantity, 可选): 剥离 YAML 引号并 trim；空值跳过，非空经 base.quantity 校验后输出。

  边界:
    - 只输出当前层字段，不输出 emptyDir 父键、apiVersion 或 kind；无有效内容时为空内容。
    - 入参视为已归一化，只校验不重复清洗；EmptyDirVolumeSource 定义之外的键静默忽略，且不识别 <字段>Alias。
    - 本模板不产生独立失败消息；委托 base.* 时保留其自身前缀。

  入参: 上下文 map，可包含以下字段:
    - medium    (string, 可选)   emptyDir 介质，取值为 Memory
    - sizeLimit (Quantity, 可选) 存储上限

  返回值: 可嵌入 Volume.emptyDir 位置的 EmptyDirVolumeSource YAML 字段片段；无有效内容时为空内容。

  示例:
    {{- include "definitions.emptyDirVolumeSource" (dict) }}
      // (空内容)
    {{- include "definitions.emptyDirVolumeSource" (dict "medium" "Memory" "sizeLimit" "1Gi") }}
      // medium: Memory
      // sizeLimit: 1Gi
*/ -}}
{{- define "definitions.emptyDirVolumeSource" -}}
  {{- $const := include "base.env" "" | fromYaml }}

  {{- /* medium（string, 可选）: YAML 标量解码后 trim；仅 Memory 合法，空值跳过，其他值中断。 */ -}}
  {{- $medium := include "base.string.normalize" (include "base.get" (list . "medium" "" "" false false)) | trim }}
  {{- if $medium }}
    {{- include "base.field" (list "medium" $medium "base.string" (list "Memory")) }}
  {{- end }}

  {{- /* sizeLimit（Quantity, 可选）: 剥离 YAML 引号并 trim；空值跳过，非空经 base.quantity 校验后输出。 */ -}}
  {{- $sizeLimit := mustRegexReplaceAll $const.SYS.YAML_QUOTED (include "base.get" (list . "sizeLimit" "" "" false false) | trim) "$1" | trim }}
  {{- if $sizeLimit }}
    {{- include "base.field" (list "sizeLimit" $sizeLimit "base.quantity") }}
  {{- end }}
{{- end }}
