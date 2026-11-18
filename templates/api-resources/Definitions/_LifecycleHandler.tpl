{{- /*
  渲染 Kubernetes LifecycleHandler 字段片段。

  行为 (按 K8s API 规范字段顺序):
    - exec (ExecAction, 四选一): 原生 map 原样委托 definitions.execAction；string array 转为 command 后委托。
    - httpGet (HTTPGetAction, 四选一): 原生 map 原样委托 definitions.httpGetAction；string 按位置解析后委托，headers 转为 httpHeaders string array。
    - sleep (SleepAction, 四选一): 原生 map 原样委托 definitions.sleepAction；integer 转为 seconds 后委托。
    - tcpSocket (TCPSocketAction, 四选一): 原生 map 原样委托 definitions.tcpSocketAction；string 按位置解析后委托。

  边界:
    - 只输出所选动作键，不包含 postStart、preStop、lifecycle 父键或 apiVersion/kind。
    - exec、httpGet、sleep、tcpSocket 必须恰好出现一个；动作缺失、多个或值类型非法时中断。
    - 抽象 exec 必须是 string array；抽象 sleep 必须是整数；抽象 httpGet 与 tcpSocket 必须是 string。
    - 抽象 httpGet 按 schema、host、port、path、headers 的位置顺序解析；未匹配位置为空字符串，headers 缺失时不设置 httpHeaders。
    - headers 括号内容先按逗号分组，再在每组内按空格分词；每两个 token 组成一个 name value 字符串，任意组分词数为奇数时中断。
    - 原生 map 的额外字段原样向下传递；四个动作子模板当前未实现，由外部提供，本模板只按名称调用。
    - 子模板结果非法 YAML 时中断；非空 map 以动作键输出。

  入参: 上下文 map，可包含 exec、httpGet、sleep、tcpSocket 之一，值为原生 map 或抽象简写。

  返回值: 可嵌入 LifecycleHandler 的 YAML 字段片段；子模板无输出时为空内容。

  示例:
    {{- include "definitions.lifecycleHandler" (dict "exec" (list "sh" "-c" "true")) }}
    {{- include "definitions.lifecycleHandler" (dict "httpGet" "HTTPS example.com 8443 /health headers (X-Foo bar, X-Baz qux)") }}
*/ -}}
{{- define "definitions.lifecycleHandler" -}}
  {{- $const := include "base.env" "" | fromYaml }}

  {{- /* exec、httpGet、sleep、tcpSocket（四选一）: 先按 key 是否存在收集动作，再中断缺失或多动作。 */ -}}
  {{- $present := list }}
  {{- range $_action := list "exec" "httpGet" "sleep" "tcpSocket" }}
    {{- if hasKey $ $_action }}
      {{- $present = mustAppend $present $_action }}
    {{- end }}
  {{- end }}
  {{- if ne (len $present) 1 }}
    {{- fail (printf "[definitions.lifecycleHandler] fields: exactly one of 'exec', 'httpGet', 'sleep' or 'tcpSocket' is required, got '%s'" (join ", " $present)) }}
  {{- end }}
  {{- $action := index $present 0 }}
  {{- $raw := get . $action }}

  {{- $ctx := dict }}
  {{- if kindIs "map" $raw }}
    {{- $ctx = $raw }}

  {{- else if eq $action "exec" }}
    {{- if not (kindIs "slice" $raw) }}
      {{- fail (printf "[definitions.lifecycleHandler] exec: must be object or string array, got '%s'" (kindOf $raw)) }}
    {{- end }}
    {{- range $_command := $raw }}
      {{- if not (kindIs "string" $_command) }}
        {{- fail "[definitions.lifecycleHandler] exec: array elements must be strings" }}
      {{- end }}
    {{- end }}
    {{- $ctx = dict "command" $raw }}

  {{- else if eq $action "httpGet" }}
    {{- if not (kindIs "string" $raw) }}
      {{- fail (printf "[definitions.lifecycleHandler] httpGet: must be object or string, got '%s'" (kindOf $raw)) }}
    {{- end }}
    {{- $_httpGet := trim $raw }}
    {{- if not (mustRegexMatch $const.K8S.LIFECYCLE_HANDLER.HTTP_GET $_httpGet) }}
      {{- fail "[definitions.lifecycleHandler] httpGet: string does not match the supported format" }}
    {{- end }}
    {{- $_scheme := mustRegexReplaceAll $const.K8S.LIFECYCLE_HANDLER.HTTP_GET $_httpGet "$1" | trim }}
    {{- $_host := mustRegexReplaceAll $const.K8S.LIFECYCLE_HANDLER.HTTP_GET $_httpGet "$2" | trim }}
    {{- $_port := mustRegexReplaceAll $const.K8S.LIFECYCLE_HANDLER.HTTP_GET $_httpGet "$3" | trim }}
    {{- $_path := mustRegexReplaceAll $const.K8S.LIFECYCLE_HANDLER.HTTP_GET $_httpGet "$4" | trim }}
    {{- $_headers := mustRegexReplaceAll $const.K8S.LIFECYCLE_HANDLER.HTTP_GET $_httpGet "$5" | trim }}
    {{- $ctx = dict "host" $_host "path" $_path "port" $_port "scheme" $_scheme }}

    {{- if $_headers }}
      {{- $httpHeaders := list }}
      {{- range $_group := mustWithout (mustRegexSplit $const.SPLIT.COMMA $_headers -1) "" }}
        {{- $_tokens := mustWithout (mustRegexSplit $const.SPLIT.SPACE_COMMA (trim $_group) -1) "" }}
        {{- if ne (mod (len $_tokens) 2) 0 }}
          {{- fail (printf "[definitions.lifecycleHandler] httpGet.headers: '%s' does not contain complete name value pairs" $_group) }}
        {{- end }}
        {{- range $i, $_token := $_tokens }}
          {{- if eq (mod $i 2) 0 }}
            {{- $httpHeaders = mustAppend $httpHeaders (printf "%s %s" $_token (index $_tokens (add $i 1))) }}
          {{- end }}
        {{- end }}
      {{- end }}
      {{- if $httpHeaders }}
        {{- $_ := set $ctx "httpHeaders" $httpHeaders }}
      {{- end }}
    {{- end }}

  {{- else if eq $action "sleep" }}
    {{- if not (or (kindIs "int" $raw) (kindIs "int64" $raw) (kindIs "float64" $raw)) }}
      {{- fail (printf "[definitions.lifecycleHandler] sleep: must be object or integer, got '%s'" (kindOf $raw)) }}
    {{- end }}
    {{- $seconds := int $raw }}
    {{- if and (kindIs "float64" $raw) (ne $raw (float64 $seconds)) }}
      {{- fail "[definitions.lifecycleHandler] sleep: integer value is required" }}
    {{- end }}
    {{- $ctx = dict "seconds" $seconds }}

  {{- else }}
    {{- if not (kindIs "string" $raw) }}
      {{- fail (printf "[definitions.lifecycleHandler] tcpSocket: must be object or string, got '%s'" (kindOf $raw)) }}
    {{- end }}
    {{- $_tcpSocket := trim $raw }}
    {{- if not (mustRegexMatch $const.K8S.LIFECYCLE_HANDLER.TCP_SOCKET $_tcpSocket) }}
      {{- fail "[definitions.lifecycleHandler] tcpSocket: string does not match the supported format" }}
    {{- end }}
    {{- $_host := mustRegexReplaceAll $const.K8S.LIFECYCLE_HANDLER.TCP_SOCKET $_tcpSocket "$1" | trim }}
    {{- $_port := mustRegexReplaceAll $const.K8S.LIFECYCLE_HANDLER.TCP_SOCKET $_tcpSocket "$2" | trim }}
    {{- $ctx = dict "host" $_host "port" $_port }}
  {{- end }}

  {{- /* 子模板委托: 动作名映射到子模板，恢复 YAML 后以同名动作键输出非空 map。 */ -}}
  {{- $defines := dict "exec" "definitions.execAction" "httpGet" "definitions.httpGetAction" "sleep" "definitions.sleepAction" "tcpSocket" "definitions.tcpSocketAction" }}
  {{- $define := get $defines $action }}
  {{- $_rendered := include $define $ctx | fromYaml }}
  {{- if eq (include "base.isFromYamlError" $_rendered) "true" }}
    {{- fail (printf "[definitions.lifecycleHandler] %s: invalid YAML output from %s" $action $define) }}
  {{- end }}
  {{- if $_rendered }}
    {{- include "base.field" (list $action $_rendered "base.map") }}
  {{- end }}
{{- end }}
