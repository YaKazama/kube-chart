{{- /*
  渲染 Kubernetes HTTPGetAction 字段片段。

  行为 (按 K8s API 规范字段顺序):
    - host (string, 可选): 非空时校验域名、IPv4 或 IPv6 地址并以带引号标量输出。
    - httpHeaders (HTTPHeader array 或 string array, 可选): 原生 map array 直接委托；string array 按空格拆分为 name/value map 后委托 definitions.httpHeader。
    - path (string, 可选): 非空时校验并归一化为绝对 URI 路径后以带引号标量输出。
    - port (integer 或 string, 必填): 数值端口校验范围，命名端口按完整 IANA_SVC_NAME 规则校验。
    - scheme (string, 可选): 大小写不敏感识别 HTTP/HTTPS，并以全大写枚举值输出。

  边界:
    - 只输出 host、httpHeaders、path、port、scheme，不包含 httpGet 父键或 apiVersion/kind。
    - host 缺失或为空时不输出；CIDR、URL 或非法地址中断。
    - httpHeaders 不是 array、元素形态混用、HTTPHeader map 缺少 name/value 或字符串 token 数不是 2 时中断。
    - port 缺失、类型非法、数值越界或命名端口不符合 IANA_SVC_NAME 时中断。
    - definitions.httpHeader 当前未实现，本模板只固定调用边界，不创建该子模板。

  入参: 上下文 map，可包含以下字段:
    - host        (string, 可选)             主机名或 IP 地址
    - httpHeaders (HTTPHeader array 或 string array, 可选) 自定义请求头
    - path        (string, 可选)             请求路径
    - port        (integer 或 string, 必填)  端口号或端口名
    - scheme      (string, 可选)             连接协议

  返回值: 可嵌入 HTTPGetAction 的 YAML 字段片段；可选字段均未生效时只输出 port。

  示例:
    {{- include "definitions.httpGetAction" (dict "host" "example.com" "path" "/health" "port" 8080 "scheme" "http") }}
*/ -}}
{{- define "definitions.httpGetAction" -}}
  {{- $const := include "base.env" "" | fromYaml }}

  {{- /* host（string, 可选）: 非空时按域名、IPv4 或 IPv6 校验，并以带引号标量输出。 */ -}}
  {{- $host := include "base.string.normalize" (include "base.get" (list . "host")) | trim }}
  {{- if $host }}
    {{- include "base.field" (list "host" (include "base.net" (list $host "dns")) "quote") }}
  {{- end }}

  {{- /* httpHeaders（HTTPHeader array 或 string array, 可选）: 恢复 array 后按首元素确定形态，统一委托 definitions.httpHeader 并按顺序收集非空 map。 */ -}}
  {{- $_httpHeadersRaw := include "base.get" (list . "httpHeaders") | trim }}
  {{- if $_httpHeadersRaw }}
    {{- $_httpHeaders := fromYamlArray $_httpHeadersRaw }}
    {{- if eq (include "base.isFromYamlArrayError" $_httpHeaders) "true" }}
      {{- fail "[definitions.httpGetAction] httpHeaders: must be array type" }}
    {{- end }}

    {{- if $_httpHeaders }}
      {{- $httpHeaders := list }}
      {{- $_firstHeader := first $_httpHeaders }}
      {{- $_mapHeaders := kindIs "map" $_firstHeader }}
      {{- $_stringHeaders := kindIs "string" $_firstHeader }}
      {{- if not (or $_mapHeaders $_stringHeaders) }}
        {{- fail (printf "[definitions.httpGetAction] httpHeaders: elements must be maps or strings, got '%s'" (kindOf $_firstHeader)) }}
      {{- end }}

      {{- range $_header := $_httpHeaders }}
        {{- $headerCtx := $_header }}
        {{- if $_mapHeaders }}
          {{- if not (kindIs "map" $_header) }}
            {{- fail "[definitions.httpGetAction] httpHeaders: map and string elements must not be mixed" }}
          {{- end }}
          {{- if or (not (hasKey $_header "name")) (not (hasKey $_header "value")) }}
            {{- fail "[definitions.httpGetAction] httpHeaders: each map element must contain name and value" }}
          {{- end }}

        {{- else }}
          {{- if not (kindIs "string" $_header) }}
            {{- fail "[definitions.httpGetAction] httpHeaders: map and string elements must not be mixed" }}
          {{- end }}
          {{- $_tokens := mustRegexSplit $const.SPLIT.SPACE (trim $_header) -1 }}
          {{- if ne (len $_tokens) 2 }}
            {{- fail (printf "[definitions.httpGetAction] httpHeaders: '%s' must contain exactly two space-separated tokens" $_header) }}
          {{- end }}
          {{- $headerCtx = dict "name" (index $_tokens 0) "value" (index $_tokens 1) }}
        {{- end }}

        {{- $_rendered := include "definitions.httpHeader" $headerCtx | fromYaml }}
        {{- if eq (include "base.isFromYamlError" $_rendered) "true" }}
          {{- fail "[definitions.httpGetAction] httpHeaders: invalid YAML output from definitions.httpHeader" }}
        {{- end }}
        {{- if not (kindIs "map" $_rendered) }}
          {{- fail "[definitions.httpGetAction] httpHeaders: definitions.httpHeader output must be map type" }}
        {{- end }}
        {{- if $_rendered }}
          {{- $httpHeaders = mustAppend $httpHeaders $_rendered }}
        {{- end }}
      {{- end }}

      {{- if $httpHeaders }}
        {{- include "base.field" (list "httpHeaders" $httpHeaders "base.slice") }}
      {{- end }}
    {{- end }}
  {{- end }}

  {{- /* path（string, 可选）: 非空时委托 base.path 的 uri 模式归一化，并以带引号标量输出。 */ -}}
  {{- $path := include "base.string.normalize" (include "base.get" (list . "path")) | trim }}
  {{- if $path }}
    {{- include "base.field" (list "path" (include "base.path" (list $path "uri")) "quote") }}
  {{- end }}

  {{- /* port（integer 或 string, 必填）: 按 YAML 标量类型分派数值与命名端口，数值委托 base.port，命名端口按完整 IANA_SVC_NAME 规则校验。 */ -}}
  {{- $_portRaw := include "base.get" (list . "port") | trim }}
  {{- if not $_portRaw }}
    {{- fail "[definitions.httpGetAction] port: required field is missing or empty" }}
  {{- end }}
  {{- $_portScalar := fromYaml (printf "v: %s" $_portRaw) }}
  {{- if eq (include "base.isFromYamlError" $_portScalar) "true" }}
    {{- fail "[definitions.httpGetAction] port: must be a valid scalar" }}
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
      {{- fail "[definitions.httpGetAction] port: required field is missing or empty" }}
    {{- end }}

    {{- if mustRegexMatch $const.TYPES.POSITIVE_INT $portName }}
      {{- include "base.field" (list "port" (include "base.port" $portName) "base.int") }}

    {{- else }}
      {{- if gt (len $portName) 15 }}
        {{- fail (printf "[definitions.httpGetAction] port: name '%s' exceeds 15 characters" $portName) }}
      {{- end }}
      {{- if not (mustRegexMatch $const.K8S.IANA_SVC_NAME $portName) }}
        {{- fail (printf "[definitions.httpGetAction] port: name '%s' must contain only lower-case letters, digits and non-adjacent hyphens, without leading or trailing hyphens" $portName) }}
      {{- end }}
      {{- if not (mustRegexMatch $const.K8S.IANA_SVC_NAME_LETTER $portName) }}
        {{- fail (printf "[definitions.httpGetAction] port: name '%s' must contain at least one letter" $portName) }}
      {{- end }}
      {{- include "base.field" (list "port" $portName "quote") }}
    {{- end }}

  {{- else }}
    {{- fail (printf "[definitions.httpGetAction] port: must be integer, numeric string or named port, got '%v' (kind: %s)" $_portValue $_portKind) }}
  {{- end }}

  {{- /* scheme（string, 可选）: 非空时归一化为全大写，并按 HTTP/HTTPS 枚举校验后以带引号标量输出。 */ -}}
  {{- $scheme := include "base.string.normalize" (include "base.get" (list . "scheme")) | trim }}
  {{- if $scheme }}
    {{- include "base.field" (list "scheme" (upper $scheme) "quote" (list "HTTP" "HTTPS")) }}
  {{- end }}
{{- end }}
