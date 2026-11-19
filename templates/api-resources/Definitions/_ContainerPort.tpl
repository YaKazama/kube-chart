{{- /*
  渲染 Kubernetes ContainerPort 字段片段。

  行为 (按 K8s API 规范字段顺序):
    - containerPort (integer, 必填): 必填校验后委托 base.port 校验 1-65535，以 integer 输出。
    - hostIP        (string, 可选): 标准 IPv4 或 IPv6，以带引号标量输出。
    - hostPort      (integer, 可选): 委托 base.port 校验 1-65535，以 integer 输出。
    - name          (string, 可选): 按 15 字符上限与完整 IANA_SVC_NAME 规则校验，以带引号标量输出。
    - protocol      (string, 可选): 强制大写后按 SCTP、TCP、UDP 枚举校验，以带引号标量输出。

  边界:
    - 只输出当前层字段，不输出 ports 父键、apiVersion 或 kind。
    - 上下文为单个 string 或 ContainerPort map；其他类型中断。
    - string 形如 [hostIP,][hostPort,]<containerPort>[/protocol][#name]，分隔符为 ,、/ 与 # 且两侧不得出现空白；hostIP 段只有同时包含 . 或 : 时才占用第一段，纯数字第一段按 hostPort 解析。
    - map 的键为 containerPort（必填）与 hostIP、hostPort、name、protocol（可选），未声明的键静默忽略；两种形态的校验与输出完全一致。
    - 整体不匹配、缺少 containerPort、端口越界、hostIP 非 IPv4/IPv6、name 非法或 protocol 非枚举时中断。
    - protocol 缺失时不输出该字段，交由 API 默认值 TCP 生效；name 的 Pod 内唯一性不在本模板校验范围。

  入参: 单个 string 标量，或键为 ContainerPort 字段的 map。

  返回值: 可嵌入 containers[].ports 元素的 ContainerPort YAML 字段片段。

  示例:
    {{- include "definitions.containerPort" "80" }}
      // containerPort: 80
    {{- include "definitions.containerPort" "127.0.0.1,8080,80/tcp#http" }}
      // containerPort: 80
      // hostIP: "127.0.0.1"
      // hostPort: 8080
      // name: "http"
      // protocol: "TCP"
    {{- include "definitions.containerPort" (dict "containerPort" 80 "protocol" "udp") }}
      // containerPort: 80
      // protocol: "UDP"
*/ -}}
{{- define "definitions.containerPort" -}}
  {{- $const := include "base.env" "" | fromYaml }}

  {{- /* 上下文分派: string 走位置解析，map 逐字段取值，归一为同一组字段后共用校验与渲染。 */ -}}
  {{- $containerPort := "" }}
  {{- $hostIP := "" }}
  {{- $hostPort := "" }}
  {{- $name := "" }}
  {{- $protocol := "" }}
  {{- $_contextKind := kindOf . }}

  {{- if eq $_contextKind "string" }}
    {{- $_pattern := $const.K8S.CONTAINER_PORT }}

    {{- /* 快速失败: 整体匹配成功后才能按捕获组位置提取 */ -}}
    {{- if not (mustRegexMatch $_pattern .) }}
      {{- fail (printf "[definitions.containerPort] input: '%s' does not match '[hostIP,][hostPort,]<containerPort>[/protocol][#name]'" .) }}
    {{- end }}
    {{- $hostIP = mustRegexReplaceAll $_pattern . "$1" | trim }}
    {{- $hostPort = mustRegexReplaceAll $_pattern . "$2" | trim }}
    {{- $containerPort = mustRegexReplaceAll $_pattern . "$3" | trim }}
    {{- $protocol = mustRegexReplaceAll $_pattern . "$4" | trim }}
    {{- $name = mustRegexReplaceAll $_pattern . "$5" | trim }}

  {{- else if eq $_contextKind "map" }}
    {{- /* 端口为整数或纯数字字符串: 剥离 YAML 外层引号后 trim，保持 base.port 的纯数字入参契约。 */ -}}
    {{- $containerPort = mustRegexReplaceAll $const.SYS.YAML_QUOTED (include "base.get" (list . "containerPort")) "$1" | trim }}
    {{- $hostPort = mustRegexReplaceAll $const.SYS.YAML_QUOTED (include "base.get" (list . "hostPort")) "$1" | trim }}

    {{- /* 字符串字段: 由 base.string.normalize 解码 YAML 标量后再 trim。 */ -}}
    {{- $hostIP = include "base.string.normalize" (include "base.get" (list . "hostIP")) | trim }}
    {{- $name = include "base.string.normalize" (include "base.get" (list . "name")) | trim }}
    {{- $protocol = include "base.string.normalize" (include "base.get" (list . "protocol")) | trim }}

  {{- else }}
    {{- fail (printf "[definitions.containerPort] input: must be string or object type, got '%s'" $_contextKind) }}
  {{- end }}

  {{- /* containerPort（integer, 必填）: 缺失或为空时中断，委托 base.port 校验 1-65535 后以 integer 输出。 */ -}}
  {{- if not $containerPort }}
    {{- fail "[definitions.containerPort] containerPort: required field is missing or empty" }}
  {{- end }}
  {{- include "base.field" (list "containerPort" (include "base.port" $containerPort) "base.int") }}

  {{- /* hostIP（string, 可选）: 非空时按标准 IPv4 或 IPv6 校验，以带引号标量输出。 */ -}}
  {{- if $hostIP }}
    {{- if not (or (mustRegexMatch $const.NET.IPV4 $hostIP) (mustRegexMatch $const.NET.IPV6 $hostIP)) }}
      {{- fail (printf "[definitions.containerPort] hostIP: '%s' is not a standard IPv4 or IPv6 address" $hostIP) }}
    {{- end }}
    {{- include "base.field" (list "hostIP" $hostIP "quote") }}
  {{- end }}

  {{- /* hostPort（integer, 可选）: 非空时委托 base.port 校验 1-65535 后以 integer 输出。 */ -}}
  {{- if $hostPort }}
    {{- include "base.field" (list "hostPort" (include "base.port" $hostPort) "base.int") }}
  {{- end }}

  {{- /* name（string, 可选）: 非空时按 15 字符上限、IANA_SVC_NAME 与含字母规则校验，以带引号标量输出。 */ -}}
  {{- if $name }}
    {{- if gt (len $name) 15 }}
      {{- fail (printf "[definitions.containerPort] name: '%s' exceeds 15 characters" $name) }}
    {{- end }}
    {{- if not (mustRegexMatch $const.K8S.IANA_SVC_NAME $name) }}
      {{- fail (printf "[definitions.containerPort] name: '%s' must contain only lower-case letters, digits and non-adjacent hyphens, without leading or trailing hyphens" $name) }}
    {{- end }}
    {{- if not (mustRegexMatch $const.K8S.IANA_SVC_NAME_LETTER $name) }}
      {{- fail (printf "[definitions.containerPort] name: '%s' must contain at least one letter" $name) }}
    {{- end }}
    {{- include "base.field" (list "name" $name "quote") }}
  {{- end }}

  {{- /* protocol（string, 可选）: 强制大写后按 SCTP、TCP、UDP 枚举校验，以带引号标量输出。 */ -}}
  {{- if $protocol }}
    {{- include "base.field" (list "protocol" (upper $protocol) "quote" (list "SCTP" "TCP" "UDP")) }}
  {{- end }}
{{- end }}
