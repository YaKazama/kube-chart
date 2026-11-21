{{- /*
  渲染 Kubernetes VolumeDevice 字段片段。

  行为 (按 K8s API 规范字段顺序):
    - devicePath (string, 必填): 必须为绝对路径，经 base.path 的 abs 模式归一化后以带引号标量输出。
    - name       (string, 必填): 按 RFC1123 Label（最长 63 字符）校验后以带引号标量输出。

  边界:
    - 只输出当前层字段，不输出 volumeDevices 父键、apiVersion 或 kind。
    - 上下文为 VolumeDevice map；string 简写由父模板空间的 definitions.container.array 归一化后再传入。
    - 两个字段同时为空时无输出；仅其中一个为空时中断。
    - map 只读取 name 与 devicePath，未声明的键静默忽略；base.get 默认开启别名，因此 nameAlias、devicePathAlias 隐式生效。
    - name 与 devicePath 只接受 string 标量；非 string 标量由 base.string.normalize 中断，null 或空字符串按未提供处理。
    - name 的 RFC1123 Label 校验由 base.rfc 中断；devicePath 的绝对路径校验由 base.path 中断。

  入参: 键为 name、devicePath 的 map。

  返回值: 可嵌入 containers[].volumeDevices 元素的 VolumeDevice YAML 字段片段；两个字段同时为空时为空内容。

  示例:
    {{- include "definitions.volumeDevice" (dict "name" "data" "devicePath" "/dev/xvda") }}
      // devicePath: "/dev/xvda"
      // name: "data"
*/ -}}
{{- define "definitions.volumeDevice" -}}
  {{- $name := include "base.string.normalize" (include "base.get" (list . "name")) | trim }}
  {{- $devicePath := include "base.string.normalize" (include "base.get" (list . "devicePath")) | trim }}

  {{- if or $name $devicePath }}
    {{- /* devicePath（string, 必填）: 绝对路径归一化与校验，以带引号标量输出。 */ -}}
    {{- if not $devicePath }}
      {{- fail "[definitions.volumeDevice] devicePath: required field is missing or empty" }}
    {{- end }}
    {{- include "base.field" (list "devicePath" (include "base.path" (list $devicePath "abs")) "quote") }}

    {{- /* name（string, 必填）: RFC1123 Label 校验，以带引号标量输出。 */ -}}
    {{- if not $name }}
      {{- fail "[definitions.volumeDevice] name: required field is missing or empty" }}
    {{- end }}
    {{- include "base.field" (list "name" (include "base.rfc" (list $name "1123")) "quote") }}
  {{- end }}
{{- end }}
