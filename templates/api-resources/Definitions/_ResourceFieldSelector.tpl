{{- /*
  渲染 Kubernetes ResourceFieldSelector 字段片段。

  行为 (按 K8s API 规范字段顺序):
    - containerName (string, 可选): 非空时以带引号标量输出。
    - divisor (Quantity, 可选): 形态需与 resource 类型匹配；cpu 的无单位整数保持不带引号的数字，cpu 的小数核值换算为毫核，cpu 整数毫核与字节单位取值以带引号字符串输出。
    - resource (string, 必填): 按 EnvVarSource 支持的资源名校验后以带引号标量输出。

  边界:
    - 只输出 containerName、divisor 与 resource，不包含 resourceFieldRef 父键。
    - 除上述三个字段以外的入参字段静默忽略。
    - resource 与 divisor 的允许形态由 base.env 的 K8S.RESOURCE_FIELD、K8S.DIVISOR_CPU、K8S.DIVISOR_SIZE 收口。
    - cpu 允许无单位整数、无单位小数与整数毫核；memory 与 ephemeral-storage 必须带字节单位。
    - cpu 小数核值统一换算为毫核，如 1.5 输出 1500m、0.5 输出 500m；量级不限，2Mi、128Mi、1000m 等均为合法输入。
    - divisor 缺省或为空白时不输出，不补官方默认值 1。
    - 不校验 containerName 对应的容器是否存在，不处理 EnvFiles 特性门禁。

  入参: 上下文 map，可包含以下字段:
    - containerName (string, 可选)   容器名，在卷场景下必填
    - divisor       (Quantity, 可选) 输出的量值单位，缺省等价于 1
    - resource      (string, 必填)   所选资源，如 limits.cpu

  返回值: 可嵌入 resourceFieldRef 位置的 YAML 字段片段。

  示例:
    {{- include "definitions.resourceFieldSelector" (dict "resource" "limits.cpu") }}
    {{- include "definitions.resourceFieldSelector" (dict "containerName" "app" "divisor" "1m" "resource" "limits.cpu") }}
    {{- include "definitions.resourceFieldSelector" (dict "divisor" "1.5" "resource" "limits.cpu") }}
*/ -}}
{{- define "definitions.resourceFieldSelector" -}}
  {{- $const := include "base.env" "" | fromYaml }}

  {{- /* containerName（string, 可选）: 非空时以带引号标量输出。 */ -}}
  {{- $containerName := include "base.string.normalize" (include "base.get" (list . "containerName")) | trim }}
  {{- if $containerName }}
    {{- include "base.field" (list "containerName" $containerName "quote") }}
  {{- end }}

  {{- /* resource（string, 必填）: 解码后判空，再按 K8S.RESOURCE_FIELD 限定为官方支持的资源名；输出调用推迟到 divisor 之后以保持字段顺序。 */ -}}
  {{- $resource := include "base.string.normalize" (include "base.get" (list . "resource")) | trim }}
  {{- if not $resource }}
    {{- fail "[definitions.resourceFieldSelector] resource: required field is missing or empty" }}
  {{- end }}
  {{- if not (mustRegexMatch $const.K8S.RESOURCE_FIELD $resource) }}
    {{- fail (printf "[definitions.resourceFieldSelector] resource: '%s' is not a supported resource" $resource) }}
  {{- end }}

  {{- /* divisor（Quantity, 可选）: 剥离 YAML 引号并 trim 后为空时按缺省处理；非空时按 resource 类型选择形态白名单并经 base.quantity 复核，cpu 小数核值换算为整数毫核。 */ -}}
  {{- $divisor := mustRegexReplaceAll $const.SYS.YAML_QUOTED (include "base.get" (list . "divisor") | trim) "$1" | trim }}
  {{- if $divisor }}
    {{- $isCpu := hasSuffix ".cpu" $resource }}
    {{- if not (mustRegexMatch (ternary $const.K8S.DIVISOR_CPU $const.K8S.DIVISOR_SIZE $isCpu) $divisor) }}
      {{- fail (printf "[definitions.resourceFieldSelector] divisor: '%s' is not allowed for resource '%s'" $divisor $resource) }}
    {{- end }}

    {{- /* cpu 小数核值换算为整数毫核；cpu 无单位整数以数字标量输出，其余形态以带引号字符串输出。 */ -}}
    {{- $hasFraction := and $isCpu (contains "." $divisor) }}
    {{- $isPlain := and $isCpu (not $hasFraction) (not (hasSuffix "m" $divisor)) }}
    {{- if $hasFraction }}
      {{- $_cores := mustRegexReplaceAll $const.K8S.DIVISOR_CPU $divisor "$2" }}
      {{- $_fraction := mustRegexReplaceAll $const.K8S.DIVISOR_CPU $divisor "$3" }}
      {{- $_fractionMilli := atoi (replace " " "0" (printf "%-3s" $_fraction)) }}
      {{- $divisor = printf "%dm" (add (mul (atoi $_cores) 1000) $_fractionMilli) }}
    {{- end }}
    {{- include "base.field" (list "divisor" $divisor "base.quantity") }}
  {{- end }}

  {{- include "base.field" (list "resource" $resource "quote") }}
{{- end }}
