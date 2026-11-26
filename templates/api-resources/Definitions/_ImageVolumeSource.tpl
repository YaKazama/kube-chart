{{- /*
  渲染 Kubernetes ImageVolumeSource 字段片段。

  行为 (按 K8s API 规范字段顺序):
    - pullPolicy (string, 可选): 解码后 trim；空值跳过，非空时按官方枚举大小写敏感校验并以带引号标量输出。
    - reference  (string, 必填): 解码后 trim 判空；非空时以带引号标量输出。

  边界:
    - 只输出当前层字段，不输出 image 父键、apiVersion 或 kind；reference 必输出。
    - 上下文为 ImageVolumeSource map；string 简写由父模板 definitions.volume 归一化后再传入。
    - map 只读取 pullPolicy 与 reference，未声明的键静默忽略；base.get 默认开启别名，因此 pullPolicyAlias、referenceAlias 隐式生效。
    - 两个字段只接受 string 标量；非 string 标量由 base.string.normalize 中断，null 或空字符串按未提供处理。
    - pullPolicy 的枚举校验由 base.field 中断并给出允许值；reference 的非空校验由本模板中断。

  入参: 上下文 map，可包含以下字段:
    - pullPolicy (string, 可选) 拉取策略，取值为 Always、IfNotPresent、Never
    - reference  (string, 必填) 镜像或制品引用

  返回值: 可嵌入 Volume.image 位置的 ImageVolumeSource YAML 字段片段。

  示例:
    {{- include "definitions.imageVolumeSource" (dict "reference" "nginx:1.27") }}
      // reference: "nginx:1.27"
    {{- include "definitions.imageVolumeSource" (dict "reference" "nginx:1.27" "pullPolicy" "Always") }}
      // pullPolicy: "Always"
      // reference: "nginx:1.27"
*/ -}}
{{- define "definitions.imageVolumeSource" -}}
  {{- /* pullPolicy（string, 可选）: 解码后 trim；空值跳过，非空时按官方枚举大小写敏感校验并以带引号标量输出。 */ -}}
  {{- $pullPolicy := include "base.string.normalize" (include "base.get" (list . "pullPolicy")) | trim }}
  {{- if $pullPolicy }}
    {{- include "base.field" (list "pullPolicy" $pullPolicy "quote" (list "Always" "IfNotPresent" "Never")) }}
  {{- end }}

  {{- /* reference（string, 必填）: 解码后 trim 判空，以带引号标量输出。 */ -}}
  {{- $reference := include "base.string.normalize" (include "base.get" (list . "reference")) | trim }}
  {{- if not $reference }}
    {{- fail "[definitions.imageVolumeSource] reference: required field is missing or empty" }}
  {{- end }}
  {{- include "base.field" (list "reference" $reference "quote") }}
{{- end }}
