{{- /*
  渲染 Kubernetes VolumeDevice 字段片段。

  行为 (按 K8s API 规范字段顺序):
    - devicePath (string, 必填): 必须为绝对路径，经 base.path 的 abs 模式归一化后以带引号标量输出。
    - name       (string, 必填): 按 RFC1123 Label（最长 63 字符）校验后以带引号标量输出。

  边界:
    - 只输出当前层字段，不输出 volumeDevices 父键、apiVersion 或 kind。
    - 上下文为单个 string 或 map；其他类型中断。
    - string 形如 <name> <devicePath>，分隔符为空格或逗号，允许连续与混用；拆分由父模板空间的 definitions.container.array.normalize 负责，超过两个非空段时由其中断。
    - 两个字段同时为空时无输出；仅其中一个为空时中断；仅分隔符 string 按同时为空处理。
    - map 只读取 name 与 devicePath，未声明的键静默忽略；base.get 默认开启别名，因此 nameAlias、devicePathAlias 隐式生效。
    - name 与 devicePath 只接受 string 标量；非 string 标量由 base.string.normalize 中断，null 或空字符串按未提供处理。
    - name 的 RFC1123 Label 校验由 base.rfc 中断；devicePath 的绝对路径校验由 base.path 中断。

  入参: 单个 string 标量，或键为 name、devicePath 的 map。

  返回值: 可嵌入 containers[].volumeDevices 元素的 VolumeDevice YAML 字段片段；两个字段同时为空时为空内容。

  示例:
    {{- include "definitions.volumeDevice" "data /dev/xvda" }}
      // devicePath: "/dev/xvda"
      // name: "data"
    {{- include "definitions.volumeDevice" (dict "name" "data" "devicePath" "/dev/xvda") }}
      // devicePath: "/dev/xvda"
      // name: "data"
*/ -}}
{{- define "definitions.volumeDevice" -}}
  {{- $name := "" }}
  {{- $devicePath := "" }}
  {{- $_contextKind := kindOf . }}

  {{- if eq $_contextKind "string" }}
    {{- $_normalizedRaw := include "definitions.container.array.normalize" . | trim }}
    {{- $_normalized := $_normalizedRaw | fromYaml }}
    {{- if eq (include "base.isFromYamlError" $_normalized) "true" }}
      {{- fail "[definitions.volumeDevice] input: invalid YAML output from definitions.container.array.normalize" }}
    {{- end }}
    {{- $name = include "base.string.normalize" (include "base.get" (list $_normalized "name")) | trim }}
    {{- $devicePath = include "base.string.normalize" (include "base.get" (list $_normalized "devicePath")) | trim }}

  {{- else if eq $_contextKind "map" }}
    {{- $name = include "base.string.normalize" (include "base.get" (list . "name")) | trim }}
    {{- $devicePath = include "base.string.normalize" (include "base.get" (list . "devicePath")) | trim }}

  {{- else }}
    {{- fail (printf "[definitions.volumeDevice] input: must be string or object type, got '%s'" $_contextKind) }}
  {{- end }}

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
