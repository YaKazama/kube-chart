{{- /*
  渲染 Kubernetes ContainerResizePolicy 字段片段。

  行为 (按 K8s API 规范字段顺序):
    - resourceName  (string, 必填): 取值 cpu 或 memory，大小写敏感；以带引号标量输出。
    - restartPolicy (string, 可选): 取值 NotRequired 或 RestartContainer，大小写敏感；以带引号标量输出。

  边界:
    - 只输出当前层字段，不输出 resizePolicy 父键、apiVersion 或 kind。
    - 上下文为 string 或 map；其他类型中断。
    - string 形如 resourceName [restartPolicy]，按 SPLIT.SPACE_COMMA 匹配范围拆分后按位置取值：第 1 段为 resourceName，第 2 段为 restartPolicy；空段不剔除，按其位置参与必填与可选项判断；多于 2 段时格式不合法并中断。
    - map 只读取 resourceName 与 restartPolicy，其他键不参与校验与输出，也不导致中断。
    - resourceName 缺失、为 null 或为空时中断；restartPolicy 缺失、为 null 或为空时省略，交由 API 默认值 NotRequired 生效。
    - 两个字段只接受 string 类型，非 string 类型由 base.string.normalize 中断；枚举比较大小写敏感，未命中时由 base.field 中断并给出合法范围。
    - base.get 默认开启别名识别，因此 map 同级 resourceNameAlias、restartPolicyAlias 隐式生效。

  入参: 单个 string 标量，或键为 resourceName、restartPolicy 的 map。

  返回值: 可嵌入 containers[].resizePolicy 元素的 ContainerResizePolicy YAML 字段片段。

  示例:
    {{- include "definitions.containerResizePolicy" "cpu" }}
      // resourceName: "cpu"
    {{- include "definitions.containerResizePolicy" "memory,RestartContainer" }}
      // resourceName: "memory"
      // restartPolicy: "RestartContainer"
    {{- include "definitions.containerResizePolicy" (dict "resourceName" "cpu" "restartPolicy" "NotRequired") }}
      // resourceName: "cpu"
      // restartPolicy: "NotRequired"
*/ -}}
{{- define "definitions.containerResizePolicy" -}}
  {{- $const := include "base.env" "" | fromYaml }}

  {{- /* 上下文分派: string 按位置拆分，map 逐字段取值，归一为同一组字段后共用校验与渲染。 */ -}}
  {{- $resourceName := "" }}
  {{- $restartPolicy := "" }}
  {{- $_contextKind := kindOf . }}

  {{- if eq $_contextKind "string" }}
    {{- $_parts := mustRegexSplit $const.SPLIT.SPACE_COMMA (trim .) -1 }}
    {{- if gt (len $_parts) 2 }}
      {{- fail (printf "[definitions.containerResizePolicy] input: '%s' must contain at most two segments, got '%d'" . (len $_parts)) }}
    {{- end }}
    {{- $resourceName = index $_parts 0 }}
    {{- if ge (len $_parts) 2 }}
      {{- $restartPolicy = index $_parts 1 }}
    {{- end }}

  {{- else if eq $_contextKind "map" }}
    {{- $resourceName = include "base.string.normalize" (include "base.get" (list . "resourceName")) | trim }}
    {{- $restartPolicy = include "base.string.normalize" (include "base.get" (list . "restartPolicy")) | trim }}

  {{- else }}
    {{- fail (printf "[definitions.containerResizePolicy] input: must be string or object type, got '%s'" $_contextKind) }}
  {{- end }}

  {{- /* resourceName（string, 必填）: 缺失或为空时中断，按 cpu、memory 枚举校验后以带引号标量输出。 */ -}}
  {{- if not $resourceName }}
    {{- fail "[definitions.containerResizePolicy] resourceName: required field is missing or empty" }}
  {{- end }}
  {{- include "base.field" (list "resourceName" $resourceName "quote" (list "cpu" "memory")) }}

  {{- /* restartPolicy（string, 可选）: 非空时按 NotRequired、RestartContainer 枚举校验，以带引号标量输出。 */ -}}
  {{- if $restartPolicy }}
    {{- include "base.field" (list "restartPolicy" $restartPolicy "quote" (list "NotRequired" "RestartContainer")) }}
  {{- end }}
{{- end }}
