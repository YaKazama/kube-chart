{{- /*
  渲染 Kubernetes TCPSocketAction 字段片段。

  行为 (按 K8s API 规范字段顺序):
    - host (string, 可选): 非空时校验域名、IPv4 或 IPv6 地址并以带引号标量输出。
    - port (integer 或 string, 必填): 数值端口校验范围，命名端口按完整 IANA_SVC_NAME 规则校验。

  边界:
    - 只输出 host、port，不包含 tcpSocket 父键或 apiVersion/kind。
    - host 缺失或为空时不输出；CIDR、URL 或非法地址中断。
    - port 缺失、类型非法、数值越界或命名端口不符合 IANA_SVC_NAME 时中断。

  入参: 上下文 map，可包含以下字段:
    - host (string, 可选)             主机名或 IP 地址
    - port (integer 或 string, 必填)  端口号或端口名

  返回值: 可嵌入 TCPSocketAction 的 YAML 字段片段；可选字段均未生效时只输出 port。

  示例:
    {{- include "definitions.tcpSocketAction" (dict "host" "example.com" "port" 8080) }}
*/ -}}
{{- define "definitions.tcpSocketAction" -}}
  {{- /* host（string, 可选）: 非空时按域名、IPv4 或 IPv6 校验，并以带引号标量输出。 */ -}}
  {{- $host := include "base.string.normalize" (include "base.get" (list . "host")) | trim }}
  {{- if $host }}
    {{- include "base.field" (list "host" (include "base.net" (list $host "dns")) "quote") }}
  {{- end }}

  {{- /* port（integer 或 string, 必填）: 按 YAML 标量类型分派数值与命名端口，数值委托 base.port，命名端口按完整 IANA_SVC_NAME 规则校验。 */ -}}
  {{- $_portRaw := include "base.get" (list . "port") | trim }}
  {{- if not $_portRaw }}
    {{- fail "[definitions.tcpSocketAction] port: required field is missing or empty" }}
  {{- end }}
  {{- $_portScalar := fromYaml (printf "v: %s" $_portRaw) }}
  {{- if eq (include "base.isFromYamlError" $_portScalar) "true" }}
    {{- fail "[definitions.tcpSocketAction] port: must be a valid scalar" }}
  {{- end }}
  {{- $_portValue := $_portScalar.v }}
  {{- $_portKind := kindOf $_portValue }}

  {{- /* Helm 4 的 fromYaml 将 YAML 数值解析为 float64；无小数部分时归一为 int，保持 base.port 的既有入参契约。 */ -}}
  {{- if and (eq $_portKind "float64") (eq $_portValue (floor $_portValue)) }}
    {{- $_portValue = int $_portValue }}
    {{- $_portKind = "int" }}
  {{- end }}

  {{- if or (eq $_portKind "int") (eq $_portKind "int64") }}
    {{- include "base.field" (list "port" (include "base.port" $_portValue) "base.int") }}

  {{- else if eq $_portKind "string" }}
    {{- $portName := trim $_portValue }}
    {{- if not $portName }}
      {{- fail "[definitions.tcpSocketAction] port: required field is missing or empty" }}
    {{- end }}
    {{- $const := include "base.env" "" | fromYaml }}

    {{- if mustRegexMatch $const.TYPES.POSITIVE_INT $portName }}
      {{- include "base.field" (list "port" (include "base.port" $portName) "base.int") }}

    {{- else }}
      {{- if gt (len $portName) 15 }}
        {{- fail (printf "[definitions.tcpSocketAction] port: name '%s' exceeds 15 characters" $portName) }}
      {{- end }}
      {{- if not (mustRegexMatch $const.K8S.IANA_SVC_NAME $portName) }}
        {{- fail (printf "[definitions.tcpSocketAction] port: name '%s' must contain only lower-case letters, digits and non-adjacent hyphens, without leading or trailing hyphens" $portName) }}
      {{- end }}
      {{- if not (mustRegexMatch $const.K8S.IANA_SVC_NAME_LETTER $portName) }}
        {{- fail (printf "[definitions.tcpSocketAction] port: name '%s' must contain at least one letter" $portName) }}
      {{- end }}
      {{- include "base.field" (list "port" $portName "quote") }}
    {{- end }}

  {{- else }}
    {{- fail (printf "[definitions.tcpSocketAction] port: must be integer, numeric string or named port, got '%v' (kind: %s)" $_portValue $_portKind) }}
  {{- end }}
{{- end }}
