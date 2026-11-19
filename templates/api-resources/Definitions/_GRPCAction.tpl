{{- /*
  渲染 Kubernetes GRPCAction 字段片段。

  行为 (按 K8s API 规范字段顺序):
    - port (integer 或 string, 必填): 数值端口校验范围，命名端口按完整 IANA_SVC_NAME 规则校验。
    - service (string, 可选): 非空时以带引号标量输出。

  边界:
    - 只输出 port、service，不包含 grpc 父键或 apiVersion/kind。
    - port 缺失、null、空字符串、类型非法、数值越界或命名端口不符合 IANA_SVC_NAME 时中断。
    - service 缺失或为空时省略；非 string 标量中断。
    - 允许命名端口与官方 GRPCAction.port 的 integer 类型不一致，由调用方确保端口形态与集群校验一致。

  入参: 上下文 map，可包含以下字段:
    - port    (integer 或 string, 必填) 端口号或端口名
    - service (string, 可选)             gRPC 健康检查服务名

  返回值: 可嵌入 GRPCAction 的 YAML 字段片段；service 未生效时只输出 port。

  示例:
    {{- include "definitions.grpcAction" (dict "port" 8080 "service" "grpc.health.v1.Health") }}
*/ -}}
{{- define "definitions.grpcAction" -}}
  {{- $const := include "base.env" "" | fromYaml }}

  {{- /* port（integer 或 string, 必填）: 按 YAML 标量类型分派数值与命名端口，数值委托 base.port，命名端口按完整 IANA_SVC_NAME 规则校验。 */ -}}
  {{- $_portRaw := include "base.get" (list . "port") | trim }}
  {{- if not $_portRaw }}
    {{- fail "[definitions.grpcAction] port: required field is missing or empty" }}
  {{- end }}
  {{- $_portScalar := fromYaml (printf "v: %s" $_portRaw) }}
  {{- if eq (include "base.isFromYamlError" $_portScalar) "true" }}
    {{- fail "[definitions.grpcAction] port: must be a valid scalar" }}
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
      {{- fail "[definitions.grpcAction] port: required field is missing or empty" }}
    {{- end }}

    {{- if mustRegexMatch $const.TYPES.POSITIVE_INT $portName }}
      {{- include "base.field" (list "port" (include "base.port" $portName) "base.int") }}

    {{- else }}
      {{- if gt (len $portName) 15 }}
        {{- fail (printf "[definitions.grpcAction] port: name '%s' exceeds 15 characters" $portName) }}
      {{- end }}
      {{- if not (mustRegexMatch $const.K8S.IANA_SVC_NAME $portName) }}
        {{- fail (printf "[definitions.grpcAction] port: name '%s' must contain only lower-case letters, digits and non-adjacent hyphens, without leading or trailing hyphens" $portName) }}
      {{- end }}
      {{- if not (mustRegexMatch $const.K8S.IANA_SVC_NAME_LETTER $portName) }}
        {{- fail (printf "[definitions.grpcAction] port: name '%s' must contain at least one letter" $portName) }}
      {{- end }}
      {{- include "base.field" (list "port" $portName "quote") }}
    {{- end }}

  {{- else }}
    {{- fail (printf "[definitions.grpcAction] port: must be integer, numeric string or named port, got '%v' (kind: %s)" $_portValue $_portKind) }}
  {{- end }}

  {{- /* service（string, 可选）: 解码后 trim，非空时以带引号标量输出，缺失或为空时省略。 */ -}}
  {{- $service := include "base.string.normalize" (include "base.get" (list . "service")) | trim }}
  {{- if $service }}
    {{- include "base.field" (list "service" $service "quote") }}
  {{- end }}
{{- end }}
