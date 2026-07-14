{{- /*
  渲染 Kubernetes ServerAddressByClientCIDR 资源。参考 https://kubernetes.io/docs/reference/kubernetes-api/definitions/server-address-by-client-cidr-v1-meta/#ServerAddressByClientCIDR

  行为 (按 K8s API 规范字段顺序):
    - clientCIDR (string, 必填): "CIDR" 形式, 渲染模板 base.string。
    - serverAddress (string, 必填): "IP" 形式, 渲染模板 base.string。
    - 禁止渲染 status、metadata 字段 (ServerAddressByClientCIDR 在 K8s 中无 ObjectMeta 语义)。

  核心字段: 上下文 map, 由 definitions.APIGroup 解析后传入, 可包含以下字段:
    - clientCIDR      (string, 必填)  CIDR 格式, 例如 "10.0.0.0/24"
    - serverAddress   (string, 必填)  IP/域名/带端口, 例如 "10.0.0.1"

  返回值: ServerAddressByClientCIDR 资源 YAML 字段 (不含顶级 "---", 由调用方决定)

  示例:
    {{- include "definitions.serverAddressByClientCIDR" . }}
*/ -}}
{{- define "definitions.serverAddressByClientCIDR" -}}
  {{- /* Step 1: clientCIDR (string, 必填): "CIDR" 形式, 上游 APIGroup 已通过 API_GROUP.SERVER_ADDRESS_BY_CLIENT_CIDR 正则分组提取 (${1}) */ -}}
  {{- $_clientCIDR := include "base.get" (list . "clientCIDR") }}
  {{- if or (not $_clientCIDR) (eq $_clientCIDR "null") }}
    {{- fail "[definitions.serverAddressByClientCIDR] clientCIDR: required field is missing or empty" }}
  {{- end }}
  {{- include "base.field" (list "clientCIDR" $_clientCIDR "base.string") }}

  {{- /* Step 2: serverAddress (string, 必填): "IP" 形式, 上游 APIGroup 已通过 API_GROUP.SERVER_ADDRESS_BY_CLIENT_CIDR 正则分组提取 (${2}) */ -}}
  {{- $_serverAddress := include "base.get" (list . "serverAddress") }}
  {{- if or (not $_serverAddress) (eq $_serverAddress "null") }}
    {{- fail "[definitions.serverAddressByClientCIDR] serverAddress: required field is missing or empty" }}
  {{- end }}
  {{- include "base.field" (list "serverAddress" $_serverAddress "base.string") }}
{{- end }}
