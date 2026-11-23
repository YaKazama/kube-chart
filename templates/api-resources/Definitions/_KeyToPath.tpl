{{- /*
  渲染 Kubernetes KeyToPath 字段片段。

  行为 (按 K8s API 规范字段顺序):
    - key  (string, 必填): 解码后 trim 判空，按 ConfigMap/Secret data key 字符集校验，并以带引号标量输出。
    - mode (integer, 可选): 接受八进制 0000-0777 或十进制 0-511 的数值/字符串，归一化为十进制 int 输出；空值省略。
    - path (string, 必填): 解码后 trim 判空，归一化为相对路径并拒绝绝对路径；归一化结果为 `..` 或以 `../` 开头时中断；以带引号标量输出。

  边界:
    - 只读取 key、mode、path，其他字段静默忽略；按 key、mode、path 顺序输出已生效字段。
    - key 的字符集由 base.env 的 K8S.DATA_KEY 收口，不限首尾字符与最大长度。
    - path 的 trim 与 `.` / `..` 段归一化由 base.path 的 rel 模式完成；前导 `..` 由本模板补足拒绝。
    - mode 的归一化由 base.fileMode 完成，与 defaultMode 语义一致。

  入参: map，形如 `{key: "LOG_LEVEL", path: "app/config.conf", mode: "0400"}`。

  返回值: 可嵌入 KeyToPath 数组元素的 YAML 字段片段。

  示例:
    {{- include "definitions.keyToPath" (dict "key" "LOG_LEVEL" "path" "app/config.conf") }}
      // key: "LOG_LEVEL"
      // path: "app/config.conf"
    {{- include "definitions.keyToPath" (dict "key" "LOG_LEVEL" "path" "a/../b" "mode" "0400") }}
      // key: "LOG_LEVEL"
      // mode: 256
      // path: "b"
*/ -}}
{{- define "definitions.keyToPath" -}}
  {{- $const := include "base.env" "" | fromYaml }}

  {{- /* key（string, 必填）: 解码后 trim 判空并按 data key 字符集校验，再以带引号标量输出。 */ -}}
  {{- $key := include "base.string.normalize" (include "base.get" (list . "key")) | trim }}
  {{- if not $key }}
    {{- fail "[definitions.keyToPath] key: required field is missing or empty" }}
  {{- end }}
  {{- if not (mustRegexMatch $const.K8S.DATA_KEY $key) }}
    {{- fail (printf "[definitions.keyToPath] key: '%s' is not a valid data key" $key) }}
  {{- end }}
  {{- include "base.field" (list "key" $key "quote") }}

  {{- /* mode（integer, 可选）: 剥离 YAML 引号后归一化为十进制 int，显式 0 有效。 */ -}}
  {{- $_modeRaw := include "base.get" (list . "mode") | trim }}
  {{- if $_modeRaw }}
    {{- $mode := mustRegexReplaceAll $const.SYS.YAML_QUOTED $_modeRaw "$1" | trim }}
    {{- if $mode }}
      {{- include "base.field" (list "mode" (include "base.fileMode" $mode) "base.int") }}
    {{- end }}
  {{- end }}

  {{- /* path（string, 必填）: 解码后 trim 判空，经 rel 模式归一化并拒绝前导 `..`，再以带引号标量输出。 */ -}}
  {{- $path := include "base.string.normalize" (include "base.get" (list . "path")) | trim }}
  {{- if not $path }}
    {{- fail "[definitions.keyToPath] path: required field is missing or empty" }}
  {{- end }}
  {{- $path = include "base.path" (list $path "rel") }}
  {{- if or (eq $path "..") (hasPrefix "../" $path) }}
    {{- fail (printf "[definitions.keyToPath] path: '%s' must not be '..' or start with '../'" $path) }}
  {{- end }}
  {{- include "base.field" (list "path" $path "quote") }}
{{- end }}
