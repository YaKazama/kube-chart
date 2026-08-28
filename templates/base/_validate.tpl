{{- /*
  校验数值是否满足下限或闭区间。

  行为:
    - 单值时原样返回；双值时校验不小于下限；三值时校验位于闭区间。
    - 仅接受 int、int64、float64 组成的 slice；非法输入立即中断渲染。

  入参: list [数值, 最小值, 最大值]；只传数值时不做范围校验，最大值可选。

  边界: 只执行数值区间校验，不转换类型、不定义业务字段范围。

  返回值: 校验通过的数值。

  示例:
    {{- include "base.int.range" (list 5) }}         // 5
    {{- include "base.int.range" (list 5 3) }}       // 5
    {{- include "base.int.range" (list 5 3 10) }}    // 5
    {{- include "base.int.range" (list 5 10) }}      // [base.int.range] num 5 not in [10, +∞) (kind: int)
    {{- include "base.int.range" "abc" }}           // [base.int.range] parameter: must be slice type, got 'abc' (kind: string)
    {{- include "base.int.range" (list "abc" 3) }}  // [base.int.range] parameter 0 (num): expected number type, got 'abc' (kind: string)
*/ -}}
{{- define "base.int.range" -}}
  {{- /* 快速失败: 入参必须为 slice */ -}}
  {{- if not (kindIs "slice" .) }}
    {{- fail (printf "[base.int.range] parameter: must be slice type, got '%s'" (kindOf .)) }}
  {{- end }}

  {{- $len := len . }}
  {{- /* 快速失败: 长度必须为 1、2 或 3 */ -}}
  {{- if lt $len 1 }}
    {{- fail "[base.int.range] parameter: at least 1 element required, got 0" }}
  {{- end }}
  {{- if gt $len 3 }}
    {{- fail (printf "[base.int.range] parameter: at most 3 elements allowed (num, min, max), got '%d'" $len) }}
  {{- end }}

  {{- /* 快速失败: num 必须为数值类型 (int / int64 / float64), 使用 kindOf 一次获取, 避免重复反射 */ -}}
  {{- $num := index . 0 }}
  {{- $numType := kindOf $num }}
  {{- if not (or (eq $numType "int") (eq $numType "int64") (eq $numType "float64")) }}
    {{- fail (printf "[base.int.range] parameter 0 (num): expected number type, got '%v' (kind: %s)" $num $numType) }}
  {{- end }}

  {{- /* 单值场景: 原样返回, 无需额外校验 */ -}}
  {{- if eq $len 1 }}
    {{- $num }}

  {{- /* 双值场景: num 必须 >= min */ -}}
  {{- else if eq $len 2 }}
    {{- /* 快速失败: min 必须为数值类型 */ -}}
    {{- $min := index . 1 }}
    {{- $minType := kindOf $min }}
    {{- if not (or (eq $minType "int") (eq $minType "int64") (eq $minType "float64")) }}
      {{- fail (printf "[base.int.range] parameter 1 (min): expected number type, got '%v' (kind: %s)" $min $minType) }}
    {{- end }}
    {{- if ge $num $min }}
      {{- $num }}
    {{- else }}
      {{- fail (printf "[base.int.range] num %v not in [%v, +∞) (kind: %s)" $num $min $numType) }}
    {{- end }}

  {{- /* 三值场景: num 必须位于 [min, max] 闭区间 */ -}}
  {{- else if eq $len 3 }}
    {{- /* 快速失败: min 与 max 必须均为数值类型 */ -}}
    {{- $min := index . 1 }}
    {{- $max := index . 2 }}
    {{- $minType := kindOf $min }}
    {{- $maxType := kindOf $max }}
    {{- if not (or (eq $minType "int") (eq $minType "int64") (eq $minType "float64")) }}
      {{- fail (printf "[base.int.range] parameter 1 (min): expected number type, got '%v' (kind: %s)" $min $minType) }}
    {{- end }}
    {{- if not (or (eq $maxType "int") (eq $maxType "int64") (eq $maxType "float64")) }}
      {{- fail (printf "[base.int.range] parameter 2 (max): expected number type, got '%v' (kind: %s)" $max $maxType) }}
    {{- end }}
    {{- if and (ge $num $min) (le $num $max) }}
      {{- $num }}
    {{- else }}
      {{- fail (printf "[base.int.range] num %v not in [%v, %v] (kind: %s)" $num $min $max $numType) }}
    {{- end }}
  {{- end }}
{{- end }}


{{- /*
  校验 TCP 或 UDP 端口号是否位于 1–65535。

  行为: 接受数值或纯数字字符串，转换为 int 后校验范围；非法输入立即中断渲染。

  入参: int、int64、float64 或纯数字字符串。

  边界: 只验证端口号数值，不区分协议、命名端口或端口冲突。

  返回值: 校验通过的 int。

  示例:
    {{- include "base.port" 8080 }}    // 8080
    {{- include "base.port" "8080" }} // 8080
    {{- include "base.port" 0 }}       // [base.port] port 0 not in [1, 65535] (kind: int)
    {{- include "base.port" 99999 }}  // [base.port] port 99999 not in [1, 65535] (kind: int)
    {{- include "base.port" "abc" }}  // [base.port] parameter: expected numeric string, got 'abc' (kind: string)
    {{- include "base.port" true }}   // [base.port] parameter: expected number or numeric string, got 'true' (kind: bool)
*/ -}}
{{- define "base.port" -}}
  {{- /* 快速失败: 仅接受数值或字符串, 使用 kindOf 一次获取避免重复反射 */ -}}
  {{- $type := kindOf . }}
  {{- if not (or (eq $type "int") (eq $type "int64") (eq $type "float64") (eq $type "string")) }}
    {{- fail (printf "[base.port] parameter: expected number or numeric string, got '%v' (kind: %s)" . $type) }}
  {{- end }}

  {{- /* string 分支: 提前校验纯数字格式, 避免 Sprig int "abc" -> 0 静默错误 */ -}}
  {{- if eq $type "string" }}
    {{- $const := include "base.env" "" | fromYaml }}
    {{- if not (mustRegexMatch $const.TYPES.INT .) }}
      {{- fail (printf "[base.port] parameter: expected numeric string, got '%v' (kind: string)" .) }}
    {{- end }}
  {{- end }}

  {{- /* 转换为 int 并校验端口范围 */ -}}
  {{- $val := int . }}
  {{- if and (ge $val 1) (le $val 65535) }}
    {{- $val }}
  {{- else }}
    {{- fail (printf "[base.port] port %v not in [1, 65535] (kind: %s)" $val $type) }}
  {{- end }}
{{- end }}


{{- /*
  校验 Unix 文件模式是否位于八进制 0000–0777（十进制 0–511）。

  行为: 数值截断为 int 后委托 base.int.range 校验；字符串按 SYS.FILE_MODE 正则校验并原样返回。

  入参: int、int64、float64，或八进制/十进制文件模式字符串。

  边界: 只验证文件权限位，不处理 setuid、setgid、sticky bit 或文件系统语义。

  返回值: 数值输入返回 int，字符串输入返回原字符串。

  示例:
    {{- include "base.fileMode" 493 }}      // 493
    {{- include "base.fileMode" "0755" }}  // 0755
    {{- include "base.fileMode" 1.5 }}     // 1 (截断, 非 1.5)
    {{- include "base.fileMode" 999 }}     // [base.int.range] num 999 not in [0, 511] (kind: int)
    {{- include "base.fileMode" "9999" }}  // [base.fileMode] parameter: expected file mode string, got '9999' (kind: string)
    {{- include "base.fileMode" true }}    // [base.fileMode] parameter: expected number or file mode string, got 'true' (kind: bool)
*/ -}}
{{- define "base.fileMode" -}}
  {{- /* 快速失败: 仅接受数值或字符串 */ -}}
  {{- $type := kindOf . }}
  {{- if not (or (eq $type "int") (eq $type "int64") (eq $type "float64") (eq $type "string")) }}
    {{- fail (printf "[base.fileMode] parameter: expected number or file mode string, got '%v' (kind: %s)" . $type) }}
  {{- end }}

  {{- /* 数值分支: 截断为 int (fileMode 为 8 位位图, 丢弃 float64 小数部分), 委托 base.int.range 校验范围 */ -}}
  {{- if or (eq $type "int") (eq $type "int64") (eq $type "float64") }}
    {{- $val := int . }}
    {{- include "base.int.range" (list $val 0 511) }}

  {{- /* 字符串分支: 通过 SYS.FILE_MODE 正则校验格式 */ -}}
  {{- else }}
    {{- $const := include "base.env" "" | fromYaml }}
    {{- if not (mustRegexMatch $const.SYS.FILE_MODE .) }}
      {{- fail (printf "[base.fileMode] parameter: expected file mode string, got '%v' (kind: string)" .) }}
    {{- end }}
    {{- . }}
  {{- end }}
{{- end }}


{{- /*
  校验 IPv4 地址、域名或两者兼容的 DNS 地址。

  行为:
    - 默认使用 ip 模式；支持 ip（IPv4，可带 CIDR）、domain（仅域名）与 dns（IPv4 或域名）。
    - 使用 base.env 的网络正则；类型、模式或格式非法时立即中断渲染。

  入参: list [地址, 模式]；模式可选，默认为 ip。

  边界: 不支持 IPv6、URL、端口或 DNS 解析。

  返回值: 校验通过的原字符串。

  示例:
    {{- include "base.net" (list "192.168.1.1" "ip") }}     // 192.168.1.1
    {{- include "base.net" (list "10.0.0.0/24" "ip") }}     // 10.0.0.0/24
    {{- include "base.net" (list "example.com" "domain") }} // example.com
    {{- include "base.net" (list "1.2.3.4" "dns") }}        // 1.2.3.4
    {{- include "base.net" (list "1.2.3.4") }}              // 1.2.3.4 (默认 ip)
    {{- include "base.net" (list "bad" "ip") }}             // [base.net] ip mode: invalid value 'bad' (kind: string)
    {{- include "base.net" (list "1.2.3.4" "foo") }}        // [base.net] parameter 1 (mode): unknown mode 'foo' (kind: string)
    {{- include "base.net" (list nil "ip") }}               // [base.net] parameter 0 (value): expected string type, got '<nil>' (kind: nil)
    {{- include "base.net" "not-a-slice" }}                 // [base.net] parameter: must be slice type, got 'string'
*/ -}}
{{- define "base.net" -}}
  {{- /* 快速失败: 入参必须为 slice */ -}}
  {{- if not (kindIs "slice" .) }}
    {{- fail (printf "[base.net] parameter: must be slice type, got '%s'" (kindOf .)) }}
  {{- end }}

  {{- $len := len . }}
  {{- /* 快速失败: 长度必须为 1 或 2 */ -}}
  {{- if or (lt $len 1) (gt $len 2) }}
    {{- fail (printf "[base.net] parameter: must be list with 1 or 2 elements, got '%d'" $len) }}
  {{- end }}

  {{- /* 解析 value 与 mode (mode 默认 "ip") */ -}}
  {{- $value := index . 0 }}
  {{- $mode := "ip" }}
  {{- if ge $len 2 }}
    {{- $mode = default "ip" (index . 1) }}
  {{- end }}

  {{- /* 快速失败: value 必须为字符串 */ -}}
  {{- if not (kindIs "string" $value) }}
    {{- fail (printf "[base.net] parameter 0 (value): expected string type, got '%v' (kind: %s)" $value (kindOf $value)) }}
  {{- end }}

  {{- /* 快速失败: mode 必须为字符串 */ -}}
  {{- if not (kindIs "string" $mode) }}
    {{- fail (printf "[base.net] parameter 1 (mode): expected string type, got '%v' (kind: %s)" $mode (kindOf $mode)) }}
  {{- end }}

  {{- /* 按需加载正则常量, 仅注入本模板实际使用的键 */ -}}
  {{- $const := include "base.env" "" | fromYaml }}

  {{- /* ip 模式: IPv4 + 可选 CIDR */ -}}
  {{- if eq $mode "ip" }}
    {{- if mustRegexMatch $const.NET.IP $value }}
      {{- $value }}
    {{- else }}
      {{- fail (printf "[base.net] ip mode: invalid value '%v' (kind: string)" $value) }}
    {{- end }}

  {{- /* domain 模式: 仅域名 */ -}}
  {{- else if eq $mode "domain" }}
    {{- if mustRegexMatch $const.NET.DOMAIN_NAME $value }}
      {{- $value }}
    {{- else }}
      {{- fail (printf "[base.net] domain mode: invalid value '%v' (kind: string)" $value) }}
    {{- end }}

  {{- /* dns 模式: IPv4 或域名均可 */ -}}
  {{- else if eq $mode "dns" }}
    {{- if mustRegexMatch $const.NET.IP $value }}
      {{- $value }}
    {{- else if mustRegexMatch $const.NET.DOMAIN_NAME $value }}
      {{- $value }}
    {{- else }}
      {{- fail (printf "[base.net] dns mode: invalid value '%v' (kind: string)" $value) }}
    {{- end }}

  {{- /* 快速失败: 未知 mode */ -}}
  {{- else }}
    {{- fail (printf "[base.net] parameter 1 (mode): unknown mode '%v' (kind: string)" $mode) }}
  {{- end }}
{{- end }}


{{- /*
  校验并归一化绝对、相对或 URI 路径。

  行为:
    - 通过 trim 与 clean 去除首尾空白并解析 .、.. 段。
    - abs 只接受绝对路径，rel 只接受相对路径，uri 可按需确保尾部斜杠。

  入参: list [路径, 模式, 保留尾部斜杠]；路径与模式必填，第三项仅用于 uri 模式。

  边界: 只进行字符串路径处理，不验证实际文件系统、URI scheme 或访问权限。

  返回值: 归一化后的路径字符串。

  示例:
    {{- include "base.path" (list "/var/log" "abs") }}        // /var/log
    {{- include "base.path" (list "/foo/../bar" "abs") }}     // /bar
    {{- include "base.path" (list "logs/app" "rel") }}        // logs/app
    {{- include "base.path" (list "logs/./app" "rel") }}      // logs/app
    {{- include "base.path" (list "/api" "uri") }}            // /api
    {{- include "base.path" (list "/api/" "uri") }}           // /api
    {{- include "base.path" (list "/api" "uri" true) }}       // /api/
    {{- include "base.path" (list "/api/" "uri" true) }}      // /api/
    {{- include "base.path" (list "rel/path" "abs") }}        // [base.path] abs mode: not an absolute path, got 'rel/path' (kind: string)
    {{- include "base.path" (list "/abs/path" "rel") }}       // [base.path] rel mode: not a relative path, got '/abs/path' (kind: string)
    {{- include "base.path" (list nil "abs") }}               // [base.path] parameter 0 (path): expected string type, got '<nil>' (kind: nil)
    {{- include "base.path" (list "/abs" "foo") }}            // [base.path] parameter 1 (mode): unknown mode 'foo' (kind: string)
    {{- include "base.path" "not-a-slice" }}                  // [base.path] parameter: must be slice type, got 'string'
*/ -}}
{{- define "base.path" -}}
  {{- /* 快速失败: 入参必须为 slice; 缓存 kindOf 结果以供错误消息复用, 避免重复反射 */ -}}
  {{- $rootType := kindOf . }}
  {{- if ne $rootType "slice" }}
    {{- fail (printf "[base.path] parameter: must be slice type, got '%s'" $rootType) }}
  {{- end }}

  {{- $len := len . }}
  {{- /* 快速失败: 长度必须为 2 或 3 */ -}}
  {{- if or (lt $len 2) (gt $len 3) }}
    {{- fail (printf "[base.path] parameter: must be list with 2 or 3 elements, got '%d'" $len) }}
  {{- end }}

  {{- /* 逐项提取并校验, 校验失败立即中止 (fail-fast), 后续参数不会被读取或检查 */ -}}
  {{- $path := index . 0 }}
  {{- $pathType := kindOf $path }}
  {{- if ne $pathType "string" }}
    {{- fail (printf "[base.path] parameter 0 (path): expected string type, got '%v' (kind: %s)" $path $pathType) }}
  {{- end }}

  {{- $mode := index . 1 }}
  {{- $modeType := kindOf $mode }}
  {{- if ne $modeType "string" }}
    {{- fail (printf "[base.path] parameter 1 (mode): expected string type, got '%v' (kind: %s)" $mode $modeType) }}
  {{- end }}

  {{- /* hasSuffix 可选, 默认 false; 仅在提供时校验类型 */ -}}
  {{- $hasSuffix := false }}
  {{- if ge $len 3 }}
    {{- $hasSuffix = index . 2 }}
  {{- end }}
  {{- $suffixType := kindOf $hasSuffix }}
  {{- if ne $suffixType "bool" }}
    {{- fail (printf "[base.path] parameter 2 (hasSuffix): expected bool type, got '%v' (kind: %s)" $hasSuffix $suffixType) }}
  {{- end }}

  {{- /* 归一化一次: trim 处理首尾空白, clean 解析 "." / ".." 段 */ -}}
  {{- $normalized := $path | trim | clean }}

  {{- /* 缓存 isAbs 结果, 供 abs / rel / uri 三个分支共享 (单次调用仅执行一个分支, 但布尔缓存保证 abs 判断与 rel 取反使用同一结果) */ -}}
  {{- $isAbs := isAbs $normalized }}

  {{- /* abs 模式: 必须为绝对路径 */ -}}
  {{- if eq $mode "abs" }}
    {{- if $isAbs }}
      {{- $normalized }}
    {{- else }}
      {{- fail (printf "[base.path] abs mode: not an absolute path, got '%v' (kind: %s)" $path $pathType) }}
    {{- end }}

  {{- /* rel 模式: 必须为相对路径 */ -}}
  {{- else if eq $mode "rel" }}
    {{- if not $isAbs }}
      {{- $normalized }}
    {{- else }}
      {{- fail (printf "[base.path] rel mode: not a relative path, got '%v' (kind: %s)" $path $pathType) }}
    {{- end }}

  {{- /* uri 模式: 必须为绝对路径, hasSuffix 控制尾部斜杠 */ -}}
  {{- else if eq $mode "uri" }}
    {{- if $isAbs }}
      {{- if and $hasSuffix (not (hasSuffix $normalized "/")) }}
        {{- printf "%s/" $normalized }}
      {{- else }}
        {{- $normalized }}
      {{- end }}
    {{- else }}
      {{- fail (printf "[base.path] uri mode: not an absolute path, got '%v' (kind: %s)" $path $pathType) }}
    {{- end }}

  {{- /* 快速失败: 未知 mode */ -}}
  {{- else }}
    {{- fail (printf "[base.path] parameter 1 (mode): unknown mode '%v' (kind: string)" $mode) }}
  {{- end }}
{{- end }}


{{- /*
  基于正则校验字符串，并返回 trim 后的值。

  行为: 先 trim，再使用调用方提供的非空正则匹配；任一校验失败立即中断渲染。

  入参: list [字符串, 正则]。

  边界: 不维护正则常量，也不解释正则对应的业务语义。

  返回值: trim 后且校验通过的字符串。

  示例:
    {{- include "base.string.verify" (list "abc123" "^[a-z]+\\d+$") }}  // abc123
    {{- include "base.string.verify" (list "  abc123  " "^[a-z]+\\d+$") }}  // abc123 (先 trim 再校验)
    {{- include "base.string.verify" (list "abc" "^[a-z]+\\d+$") }}     // [base.string.verify] parameter 0 (data): regex '^[a-z]+\d+$' does not match, got 'abc' (kind: string)
    {{- include "base.string.verify" (list "abc" "") }}                 // [base.string.verify] parameter 1 (regex): must not be empty
    {{- include "base.string.verify" (list 42 "x") }}                   // [base.string.verify] parameter 0 (data): expected string type, got '42' (kind: int)
    {{- include "base.string.verify" (list "abc" 42) }}                 // [base.string.verify] parameter 1 (regex): expected string type, got '42' (kind: int)
    {{- include "base.string.verify" (list "abc") }}                    // [base.string.verify] parameter: must be list with 2 elements, got '1'
    {{- include "base.string.verify" (list nil "x") }}                  // [base.string.verify] parameter 0 (data): expected string type, got '<nil>' (kind: invalid)
    {{- include "base.string.verify" "not-a-slice" }}                   // [base.string.verify] parameter: must be slice type, got 'string'
*/ -}}
{{- define "base.string.verify" -}}
  {{- /* 快速失败: 入参必须为 slice; 缓存 kindOf 结果以供错误消息复用, 避免重复反射 */ -}}
  {{- $rootType := kindOf . }}
  {{- if ne $rootType "slice" }}
    {{- fail (printf "[base.string.verify] parameter: must be slice type, got '%s'" $rootType) }}
  {{- end }}

  {{- $len := len . }}
  {{- /* 快速失败: 长度必须等于 2 */ -}}
  {{- if ne $len 2 }}
    {{- fail (printf "[base.string.verify] parameter: must be list with 2 elements, got '%d'" $len) }}
  {{- end }}

  {{- $data := index . 0 }}
  {{- $dataType := kindOf $data }}
  {{- if ne $dataType "string" }}
    {{- fail (printf "[base.string.verify] parameter 0 (data): expected string type, got '%v' (kind: %s)" $data $dataType) }}
  {{- end }}

  {{- $regex := index . 1 }}
  {{- $regexType := kindOf $regex }}
  {{- if ne $regexType "string" }}
    {{- fail (printf "[base.string.verify] parameter 1 (regex): expected string type, got '%v' (kind: %s)" $regex $regexType) }}
  {{- end }}

  {{- /* 快速失败: regex 不允许为空; 前置类型校验已保证 $regexType == "string", 错误消息无需重复打印类型 */ -}}
  {{- if eq $regex "" }}
    {{- fail "[base.string.verify] parameter 1 (regex): must not be empty" }}
  {{- end }}

  {{- /* 关键修复: 必须先 trim 后校验, 避免 data 包含首尾空白导致 mustRegexMatch 意外不匹配 */ -}}
  {{- $trimmed := trim $data }}
  {{- if mustRegexMatch $regex $trimmed }}
    {{- $trimmed }}
  {{- else }}
    {{- fail (printf "[base.string.verify] parameter 0 (data): regex '%s' does not match, got '%v' (kind: %s)" $regex $trimmed $dataType) }}
  {{- end }}
{{- end }}
