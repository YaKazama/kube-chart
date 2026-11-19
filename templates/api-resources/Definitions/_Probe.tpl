{{- /*
  渲染 Kubernetes Probe 字段片段。

  行为 (按 K8s API 规范字段顺序):
    - exec (ExecAction, 四选一): 生效时委托 definitions.execAction 渲染。
    - failureThreshold (integer, 可选): 生效时以十进制整数输出。
    - grpc (GRPCAction, 四选一): 生效时委托 definitions.grpcAction 渲染。
    - httpGet (HTTPGetAction, 四选一): 生效时委托 definitions.httpGetAction 渲染。
    - initialDelaySeconds (integer, 可选): 生效时以十进制整数输出。
    - periodSeconds (integer, 可选): 生效时以十进制整数输出。
    - successThreshold (integer, 可选): 生效时以十进制整数输出。
    - tcpSocket (TCPSocketAction, 四选一): 生效时委托 definitions.tcpSocketAction 渲染。
    - terminationGracePeriodSeconds (integer, 可选): 生效时以十进制整数输出。
    - timeoutSeconds (integer, 可选): 生效时以十进制整数输出。

  边界:
    - 只输出上述字段，不包含 livenessProbe、readinessProbe、startupProbe 父键或 apiVersion/kind。
    - exec、grpc、httpGet、tcpSocket 按键是否存在判定互斥，最多一个；多个时中断。
    - 生效动作的值为 null 或空 map 时中断；类型既非 map 又非约定简写时中断。
    - exec 简写必须是 string array；grpc、httpGet、tcpSocket 简写必须是 string。
    - httpGet 简化按 scheme、host、port、path、headers 的位置顺序解析，headers 括号内容按逗号分组、组内按空格分词后每两个 token 组成一个 name value。
    - integer 字段只接受 int、int64 与无小数 float64；字符串、bool、带小数 float64、map 与 slice 中断。
    - definitions.grpcAction 当前未实现，由外部提供，本模板只按名称调用。
    - 子模板输出非法 YAML 时中断；子模板无输出时不产生对应字段。

  入参: 上下文 map，可包含以下字段:
    - exec                            (ExecAction, 四选一)           原生 map 或 string array
    - failureThreshold                (integer, 可选)                连续失败阈值
    - grpc                            (GRPCAction, 四选一)           原生 map 或 "[service] <port>"
    - httpGet                         (HTTPGetAction, 四选一)        原生 map 或位置化简写
    - initialDelaySeconds             (integer, 可选)                首次探测前等待秒数
    - periodSeconds                   (integer, 可选)                探测间隔秒数
    - successThreshold                (integer, 可选)                连续成功阈值
    - tcpSocket                       (TCPSocketAction, 四选一)      原生 map 或 "<host> <port>"
    - terminationGracePeriodSeconds   (integer, 可选)                探测失败后的优雅终止秒数
    - timeoutSeconds                  (integer, 可选)                探测超时秒数

  返回值: 可嵌入 Probe 位置的 YAML 字段片段；全部字段缺失时为空内容。

  示例:
    {{- include "definitions.probe" (dict "httpGet" "HTTPS example.com 8443 /health" "initialDelaySeconds" 5 "periodSeconds" 10) }}
*/ -}}
{{- define "definitions.probe" -}}
  {{- /* exec、grpc、httpGet、tcpSocket（四选一）: 先按 key 是否存在收集动作，再中断多动作，保留唯一生效动作。 */ -}}
  {{- $present := list }}
  {{- range $_action := list "exec" "grpc" "httpGet" "tcpSocket" }}
    {{- if hasKey $ $_action }}
      {{- $present = mustAppend $present $_action }}
    {{- end }}
  {{- end }}
  {{- if gt (len $present) 1 }}
    {{- fail (printf "[definitions.probe] fields: at most one of 'exec', 'grpc', 'httpGet' or 'tcpSocket' is allowed, got '%s'" (join ", " $present)) }}
  {{- end }}

  {{- /* 生效动作归一: 排除 null 与空 map 后，把 map 原样或简写解析结果作为子模板上下文。 */ -}}
  {{- $action := "" }}
  {{- $context := dict }}
  {{- if $present }}
    {{- $action = index $present 0 }}
    {{- $raw := get . $action }}
    {{- if kindIs "invalid" $raw }}
      {{- fail (printf "[definitions.probe] %s: must not be null" $action) }}
    {{- end }}

    {{- if kindIs "map" $raw }}
      {{- if not $raw }}
        {{- fail (printf "[definitions.probe] %s: must not be empty" $action) }}
      {{- end }}
      {{- $context = $raw }}

    {{- else if eq $action "exec" }}
      {{- if not (kindIs "slice" $raw) }}
        {{- fail (printf "[definitions.probe] exec: must be object or string array, got '%s'" (kindOf $raw)) }}
      {{- end }}
      {{- range $_command := $raw }}
        {{- if not (kindIs "string" $_command) }}
          {{- fail "[definitions.probe] exec: array elements must be strings" }}
        {{- end }}
      {{- end }}
      {{- $context = dict "command" $raw }}

    {{- else if eq $action "grpc" }}
      {{- $const := include "base.env" "" | fromYaml }}
      {{- if not (kindIs "string" $raw) }}
        {{- fail (printf "[definitions.probe] grpc: must be object or string, got '%s'" (kindOf $raw)) }}
      {{- end }}
      {{- $_grpc := trim $raw }}
      {{- if not (mustRegexMatch $const.K8S.GRPC_ACTION $_grpc) }}
        {{- fail "[definitions.probe] grpc: string does not match the supported format" }}
      {{- end }}
      {{- $_service := mustRegexReplaceAll $const.K8S.GRPC_ACTION $_grpc "$1" | trim }}
      {{- $_port := mustRegexReplaceAll $const.K8S.GRPC_ACTION $_grpc "$2" | trim }}
      {{- $context = dict "service" $_service "port" $_port }}

    {{- else if eq $action "httpGet" }}
      {{- $const := include "base.env" "" | fromYaml }}
      {{- if not (kindIs "string" $raw) }}
        {{- fail (printf "[definitions.probe] httpGet: must be object or string, got '%s'" (kindOf $raw)) }}
      {{- end }}
      {{- $_httpGet := trim $raw }}
      {{- if not (mustRegexMatch $const.K8S.LIFECYCLE_HANDLER.HTTP_GET $_httpGet) }}
        {{- fail "[definitions.probe] httpGet: string does not match the supported format" }}
      {{- end }}
      {{- $_scheme := mustRegexReplaceAll $const.K8S.LIFECYCLE_HANDLER.HTTP_GET $_httpGet "$1" | trim }}
      {{- $_host := mustRegexReplaceAll $const.K8S.LIFECYCLE_HANDLER.HTTP_GET $_httpGet "$2" | trim }}
      {{- $_port := mustRegexReplaceAll $const.K8S.LIFECYCLE_HANDLER.HTTP_GET $_httpGet "$3" | trim }}
      {{- $_path := mustRegexReplaceAll $const.K8S.LIFECYCLE_HANDLER.HTTP_GET $_httpGet "$4" | trim }}
      {{- $_headers := mustRegexReplaceAll $const.K8S.LIFECYCLE_HANDLER.HTTP_GET $_httpGet "$5" | trim }}
      {{- $context = dict "host" $_host "path" $_path "port" $_port "scheme" $_scheme }}

      {{- if $_headers }}
        {{- $httpHeaders := list }}
        {{- range $_group := mustWithout (mustRegexSplit $const.SPLIT.COMMA $_headers -1) "" }}
          {{- $_tokens := mustWithout (mustRegexSplit $const.SPLIT.SPACE_COMMA (trim $_group) -1) "" }}
          {{- if ne (mod (len $_tokens) 2) 0 }}
            {{- fail (printf "[definitions.probe] httpGet.headers: '%s' does not contain complete name value pairs" $_group) }}
          {{- end }}
          {{- range $i, $_token := $_tokens }}
            {{- if eq (mod $i 2) 0 }}
              {{- $httpHeaders = mustAppend $httpHeaders (printf "%s %s" $_token (index $_tokens (add $i 1))) }}
            {{- end }}
          {{- end }}
        {{- end }}
        {{- if $httpHeaders }}
          {{- $_ := set $context "httpHeaders" $httpHeaders }}·
        {{- end }}
      {{- end }}

    {{- else }}
      {{- $const := include "base.env" "" | fromYaml }}
      {{- if not (kindIs "string" $raw) }}
        {{- fail (printf "[definitions.probe] tcpSocket: must be object or string, got '%s'" (kindOf $raw)) }}
      {{- end }}
      {{- $_tcpSocket := trim $raw }}
      {{- if not (mustRegexMatch $const.K8S.LIFECYCLE_HANDLER.TCP_SOCKET $_tcpSocket) }}
        {{- fail "[definitions.probe] tcpSocket: string does not match the supported format" }}
      {{- end }}
      {{- $_host := mustRegexReplaceAll $const.K8S.LIFECYCLE_HANDLER.TCP_SOCKET $_tcpSocket "$1" | trim }}
      {{- $_port := mustRegexReplaceAll $const.K8S.LIFECYCLE_HANDLER.TCP_SOCKET $_tcpSocket "$2" | trim }}
      {{- $context = dict "host" $_host "port" $_port }}
    {{- end }}
  {{- end }}

  {{- /* 动作子模板委托: 生效动作映射到子模板并提前渲染，输出位置由官方字段顺序决定。 */ -}}
  {{- $defines := dict "exec" "definitions.execAction" "grpc" "definitions.grpcAction" "httpGet" "definitions.httpGetAction" "tcpSocket" "definitions.tcpSocketAction" }}
  {{- $actionRendered := "" }}
  {{- if $action }}
    {{- $actionRendered = include "definitions.probe.render" (dict "key" $action "define" (get $defines $action) "context" $context) }}
  {{- end }}

  {{- /* exec（ExecAction）: 生效时输出子模板结果。 */ -}}
  {{- if eq $action "exec" }}{{ $actionRendered }}{{- end }}

  {{- /* failureThreshold（integer）: 按整数语义校验后以十进制整数输出。 */ -}}
  {{- include "definitions.probe.integer" (dict "context" . "key" "failureThreshold") }}

  {{- /* grpc（GRPCAction）: 生效时输出子模板结果。 */ -}}
  {{- if eq $action "grpc" }}{{ $actionRendered }}{{- end }}

  {{- /* httpGet（HTTPGetAction）: 生效时输出子模板结果。 */ -}}
  {{- if eq $action "httpGet" }}{{ $actionRendered }}{{- end }}

  {{- /* initialDelaySeconds（integer）: 按整数语义校验后以十进制整数输出。 */ -}}
  {{- include "definitions.probe.integer" (dict "context" . "key" "initialDelaySeconds") }}

  {{- /* periodSeconds（integer）: 按整数语义校验后以十进制整数输出。 */ -}}
  {{- include "definitions.probe.integer" (dict "context" . "key" "periodSeconds") }}

  {{- /* successThreshold（integer）: 按整数语义校验后以十进制整数输出。 */ -}}
  {{- include "definitions.probe.integer" (dict "context" . "key" "successThreshold") }}

  {{- /* tcpSocket（TCPSocketAction）: 生效时输出子模板结果。 */ -}}
  {{- if eq $action "tcpSocket" }}{{ $actionRendered }}{{- end }}

  {{- /* terminationGracePeriodSeconds（integer）: 按整数语义校验后以十进制整数输出。 */ -}}
  {{- include "definitions.probe.integer" (dict "context" . "key" "terminationGracePeriodSeconds") }}

  {{- /* timeoutSeconds（integer）: 按整数语义校验后以十进制整数输出。 */ -}}
  {{- include "definitions.probe.integer" (dict "context" . "key" "timeoutSeconds") }}
{{- end }}


{{- /*
  调用动作子模板并以动作键输出非空结果。

  行为:
    - 以给定上下文调用子模板，恢复 YAML 后排除解析错误。
    - 结果非空时以动作键交给 base.field 与 base.map 渲染。

  边界:
    - 只处理单个动作的委托与输出，不负责互斥判定、形态归一或字段生效条件。
    - 子模板输出非法 YAML 时中断；空结果不产生输出。

  入参: 上下文 map，恒含以下字段:
    - key     (string, 必填) 动作键名
    - define  (string, 必填) 子模板名
    - context (map, 必填)    子模板上下文

  返回值: 以动作键开头的 YAML 字段片段；子模板无输出时为空内容。

  示例:
    {{- include "definitions.probe.render" (dict "key" "tcpSocket" "define" "definitions.tcpSocketAction" "context" (dict "port" 8080)) }}
*/ -}}
{{- define "definitions.probe.render" -}}
  {{- $_rendered := include .define .context | fromYaml }}
  {{- if eq (include "base.isFromYamlError" $_rendered) "true" }}
    {{- fail (printf "[definitions.probe] %s: invalid YAML output from %s" .key .define) }}
  {{- end }}
  {{- if $_rendered }}
    {{- include "base.field" (list .key $_rendered "base.map") }}
  {{- end }}
{{- end }}


{{- /*
  渲染 Probe 的单个 integer 字段。

  行为:
    - 通过 base.get 取值并 trim；缺失或空输出时不渲染。
    - 回读原生类型，只接受 int、int64 与无小数 float64，最终以十进制整数输出。

  边界:
    - 只处理单个阈值字段，不负责字段顺序或默认值。
    - 字符串、bool、带小数 float64、map 与 slice 中断。

  入参: 上下文 map，恒含以下字段:
    - context (map, 必填)    字段来源上下文
    - key     (string, 必填) 字段名

  返回值: 单个 YAML 键值片段；字段缺失或为空时为空内容。

  示例:
    {{- include "definitions.probe.integer" (dict "context" . "key" "periodSeconds") }}
*/ -}}
{{- define "definitions.probe.integer" -}}
  {{- $_raw := include "base.get" (list .context .key) | trim }}
  {{- if $_raw }}
    {{- $_parsed := fromYaml (printf "v: %s" $_raw) }}
    {{- if eq (include "base.isFromYamlError" $_parsed) "true" }}
      {{- fail (printf "[definitions.probe] %s: must be integer, got '%s'" .key $_raw) }}
    {{- end }}

    {{- $_value := $_parsed.v }}
    {{- $_kind := kindOf $_value }}
    {{- if not (has $_kind (list "int" "int64" "float64")) }}
      {{- fail (printf "[definitions.probe] %s: must be integer, got '%v' (kind: %s)" .key $_value $_kind) }}
    {{- end }}

    {{- if and (eq $_kind "float64") (ne $_value (floor $_value)) }}
      {{- fail (printf "[definitions.probe] %s: must be integer, got '%v'" .key $_value) }}
    {{- end }}

    {{- include "base.field" (list .key $_value "base.int") }}
  {{- end }}
{{- end }}
