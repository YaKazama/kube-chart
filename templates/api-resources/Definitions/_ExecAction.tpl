{{- /*
  渲染 Kubernetes ExecAction 字段片段。

  行为 (按 K8s API 规范字段顺序):
    - command (string array, 必填): 按输入顺序原样输出，不拆分或清洗元素；空 array 不产生输出。

  边界:
    - 只输出 command，不包含 exec、postStart、preStop 或 lifecycle 父键。
    - command 缺失、不是 array 或包含非 string 元素时中断。
    - 不校验 command 内容在容器镜像中的可执行性。

  入参: 上下文 map，必须包含 command (string array)。

  返回值: 可嵌入 ExecAction 的 YAML 字段片段；command 为空 array 时为空内容。

  示例:
    {{- include "definitions.execAction" (dict "command" (list "sh" "-c" "true")) }}
*/ -}}
{{- define "definitions.execAction" -}}
  {{- /* command（string array, 必填）: 以非 required 模式取得原始 YAML，区分缺失与空 array 后恢复并校验全部元素。 */ -}}
  {{- $_commandRaw := include "base.get" (list . "command" "" "" false) | trim }}
  {{- if not $_commandRaw }}
    {{- fail "[definitions.execAction] command: required field is missing" }}
  {{- end }}

  {{- $command := fromYamlArray $_commandRaw }}
  {{- if eq (include "base.isFromYamlArrayError" $command) "true" }}
    {{- fail "[definitions.execAction] command: must be array type" }}
  {{- end }}
  {{- range $_command := $command }}
    {{- if not (kindIs "string" $_command) }}
      {{- fail (printf "[definitions.execAction] command: elements must be strings, got '%v' (%s)" $_command (kindOf $_command)) }}
    {{- end }}
  {{- end }}

  {{- if $command }}
    {{- include "base.field" (list "command" $command "base.slice") }}
  {{- end }}
{{- end }}
