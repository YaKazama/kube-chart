{{- /*
  渲染 Kubernetes FileKeySelector 字段片段。

  行为 (按 K8s API 规范字段顺序):
    - key (string, 必填): 按 YAML 标量语义解码后以带引号标量输出，缺失或为空白时中断。
    - optional (boolean, 可选): 接受原生布尔值与字符串 true/false，显式 false 也输出。
    - path (string, 必填): 解码后判空，按相对路径归一化并拒绝 .、.. 与 ../ 前缀，以带引号标量输出。
    - volumeName (string, 必填): 解码后判空，以带引号标量输出。

  边界:
    - 只输出 key、optional、path 与 volumeName，不包含 fileKeyRef 父键。
    - 除上述四个字段以外的入参字段静默忽略。
    - path 的归一化委托 base.path 的 rel 模式；绝对路径由该能力中断并保留其消息前缀，.、.. 与 ../ 前缀由本模板拒绝。
    - optional 的字符串形态（含 "true"）同样被接受；数字、map、list 与其他字符串视为类型错误。
    - 不校验 path 指向的卷内文件是否存在，不校验 key 的字符集与长度，不处理 EnvFiles 特性门禁。

  入参: 上下文 map，可包含以下字段:
    - key        (string, 必填)   env 文件内的键名
    - optional   (boolean, 可选)  文件或键缺失时是否允许忽略
    - path       (string, 必填)   卷内相对路径
    - volumeName (string, 必填)   包含 env 文件的卷名

  返回值: 可嵌入 fileKeyRef 位置的 YAML 字段片段。

  示例:
    {{- include "definitions.fileKeySelector" (dict "volumeName" "env-vol" "path" "app.log" "key" "LOG_LEVEL") }}
    {{- include "definitions.fileKeySelector" (dict "volumeName" "env-vol" "path" "app.log" "key" "LOG_LEVEL" "optional" true) }}
*/ -}}
{{- define "definitions.fileKeySelector" -}}
  {{- $const := include "base.env" "" | fromYaml }}

  {{- /* key（string, 必填）: 解码后判空，非空时以带引号标量输出，避免数字或布尔外观的键名改变 YAML 类型。 */ -}}
  {{- $key := include "base.string.normalize" (include "base.get" (list . "key")) | trim }}
  {{- if not $key }}
    {{- fail "[definitions.fileKeySelector] key: required field is missing or empty" }}
  {{- end }}
  {{- include "base.field" (list "key" $key "quote") }}

  {{- /* optional（boolean, 可选）: 剥离 YAML 引号后交给 base.bool 做布尔类型门禁，显式 false 也输出。 */ -}}
  {{- $optional := mustRegexReplaceAll $const.SYS.YAML_QUOTED (include "base.get" (list . "optional") | trim) "$1" | trim }}
  {{- if $optional }}
    {{- include "base.field" (list "optional" $optional "base.bool") }}
  {{- end }}

  {{- /* path（string, 必填）: 解码后判空，再按相对路径归一化；结果为 .、.. 或以 ../ 开头时拒绝。 */ -}}
  {{- $path := include "base.string.normalize" (include "base.get" (list . "path")) | trim }}
  {{- if not $path }}
    {{- fail "[definitions.fileKeySelector] path: required field is missing or empty" }}
  {{- end }}
  {{- $path = include "base.path" (list $path "rel") }}
  {{- if or (eq $path ".") (eq $path "..") (hasPrefix "../" $path) }}
    {{- fail (printf "[definitions.fileKeySelector] path: must select a file within the volume, got '%s'" $path) }}
  {{- end }}
  {{- include "base.field" (list "path" $path "quote") }}

  {{- /* volumeName（string, 必填）: 解码后判空，非空时以带引号标量输出。 */ -}}
  {{- $volumeName := include "base.string.normalize" (include "base.get" (list . "volumeName")) | trim }}
  {{- if not $volumeName }}
    {{- fail "[definitions.fileKeySelector] volumeName: required field is missing or empty" }}
  {{- end }}
  {{- include "base.field" (list "volumeName" $volumeName "quote") }}
{{- end }}
