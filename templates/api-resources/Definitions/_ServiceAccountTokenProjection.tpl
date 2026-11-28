{{- /*
  渲染 Kubernetes ServiceAccountTokenProjection 字段片段。

  行为 (按 K8s API 规范字段顺序):
    - audience          (string, 可选): 解码后 trim，非空时以带引号标量输出；空值省略。
    - expirationSeconds (integer, 可选): 剥离 YAML 引号后归一化为整数并校验最小 600；空值省略。
    - path              (string, 必填): 解码后 trim 判空，归一化为相对路径并拒绝绝对路径；归一化结果为 `..` 或以 `../` 开头时中断；以带引号标量输出。

  边界:
    - 只读取 audience、expirationSeconds、path，其他字段静默忽略；按 API 顺序输出已生效字段。
    - path 的 `.`/`..` 段归一化由 base.path 的 rel 模式完成；前导 `..` 由本模板补足拒绝，与 definitions.keyToPath 一致。
    - expirationSeconds 的整数归一化由 base.int 完成，最小值由 base.int.range 校验。
    - 不校验 ServiceAccount 是否存在或 token 是否可签发。

  入参: 原生 map，形如 `{audience: "https://kubernetes.default.svc", expirationSeconds: 3600, path: "token"}`。

  返回值: 可嵌入 VolumeProjection.serviceAccountToken 位置的 YAML 字段片段。

  示例:
    {{- include "definitions.serviceAccountTokenProjection" (dict "path" "token") }}
      // path: "token"
    {{- include "definitions.serviceAccountTokenProjection" (dict "audience" "https://kubernetes.default.svc" "expirationSeconds" 3600 "path" "token") }}
      // audience: "https://kubernetes.default.svc"
      // expirationSeconds: 3600
      // path: "token"
*/ -}}
{{- define "definitions.serviceAccountTokenProjection" -}}
  {{- $const := include "base.env" "" | fromYaml }}

  {{- /* audience（string, 可选）: 解码后 trim，非空时以带引号标量输出。 */ -}}
  {{- $audience := include "base.string.normalize" (include "base.get" (list . "audience")) | trim }}
  {{- if $audience }}
    {{- include "base.field" (list "audience" $audience "quote") }}
  {{- end }}

  {{- /* expirationSeconds（integer, 可选）: 剥离 YAML 引号后归一化为整数并校验最小 600，空值省略。 */ -}}
  {{- $_expirationSecondsRaw := include "base.get" (list . "expirationSeconds") | trim }}
  {{- if $_expirationSecondsRaw }}
    {{- $expirationSeconds := mustRegexReplaceAll $const.SYS.YAML_QUOTED $_expirationSecondsRaw "$1" | trim }}
    {{- if $expirationSeconds }}
      {{- $expirationSeconds = int (include "base.int" $expirationSeconds) }}
      {{- $expirationSeconds = include "base.int.range" (list $expirationSeconds 600) }}
      {{- include "base.field" (list "expirationSeconds" $expirationSeconds "base.int") }}
    {{- end }}
  {{- end }}

  {{- /* path（string, 必填）: 解码后 trim 判空，经 rel 模式归一化并拒绝前导 `..`，再以带引号标量输出。 */ -}}
  {{- $path := include "base.string.normalize" (include "base.get" (list . "path")) | trim }}
  {{- if not $path }}
    {{- fail "[definitions.serviceAccountTokenProjection] path: required field is missing or empty" }}
  {{- end }}
  {{- $path = include "base.path" (list $path "rel") }}
  {{- if or (eq $path "..") (hasPrefix "../" $path) }}
    {{- fail (printf "[definitions.serviceAccountTokenProjection] path: '%s' must not be '..' or start with '../'" $path) }}
  {{- end }}
  {{- include "base.field" (list "path" $path "quote") }}
{{- end }}
