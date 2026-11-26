{{- /*
  渲染 Kubernetes HostPathVolumeSource 字段片段。

  行为 (按 K8s API 规范字段顺序):
    - path (string, 必填): 解码后 trim 判空，归一化为绝对路径并以带引号标量输出。
    - type (string, 可选): 解码后 trim；空值跳过，非空时按官方枚举大小写敏感校验并原样输出。

  边界:
    - 只输出当前层字段，不输出 hostPath 父键、apiVersion 或 kind；path 必输出。
    - 上下文为 HostPathVolumeSource map；string 简写由父模板 definitions.volume 归一化后再传入。
    - map 只读取 path 与 type，未声明的键静默忽略；base.get 默认开启别名，因此 pathAlias、typeAlias 隐式生效。
    - path 与 type 只接受 string 标量；非 string 标量由 base.string.normalize 中断，null 或空字符串按未提供处理。
    - path 的绝对路径归一化由 base.path 中断；type 的枚举校验由 base.field 中断并给出允许值，原生 map 的 type 不做大小写归一化。

  入参: 上下文 map，可包含以下字段:
    - path (string, 必填) 主机上的绝对路径
    - type (string, 可选) 卷类型，取值为 BlockDevice、CharDevice、Directory、DirectoryOrCreate、File、FileOrCreate、Socket

  返回值: 可嵌入 Volume.hostPath 位置的 HostPathVolumeSource YAML 字段片段。

  示例:
    {{- include "definitions.hostPathVolumeSource" (dict "path" "/data") }}
      // path: "/data"
    {{- include "definitions.hostPathVolumeSource" (dict "path" "/data" "type" "DirectoryOrCreate") }}
      // path: "/data"
      // type: DirectoryOrCreate
*/ -}}
{{- define "definitions.hostPathVolumeSource" -}}
  {{- /* path（string, 必填）: 解码后 trim 判空，经 abs 模式归一化，以带引号标量输出。 */ -}}
  {{- $path := include "base.string.normalize" (include "base.get" (list . "path")) | trim }}
  {{- if not $path }}
    {{- fail "[definitions.hostPathVolumeSource] path: required field is missing or empty" }}
  {{- end }}
  {{- include "base.field" (list "path" (include "base.path" (list $path "abs")) "quote") }}

  {{- /* type（string, 可选）: 解码后 trim；空值跳过，非空时按官方枚举大小写敏感校验并原样输出。 */ -}}
  {{- $type := include "base.string.normalize" (include "base.get" (list . "type")) | trim }}
  {{- if $type }}
    {{- include "base.field" (list "type" $type "base.string" (list "BlockDevice" "CharDevice" "Directory" "DirectoryOrCreate" "File" "FileOrCreate" "Socket")) }}
  {{- end }}
{{- end }}
