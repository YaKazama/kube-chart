{{- /*
  字典类型校验：空字典合法且渲染为 "{}"。

  行为:
    - 字典类型: 使用 toYamlPretty 渲染
    - 非字典类型: 渲染中断

  入参: 任意值，期望为字典
  返回: YAML 字符串；非字典输入时中断渲染
  错误信息包含具体值与实际类型，便于调试。

  示例:
    {{- include "base.map" (dict "a" "1" "b" "2") }}  // a: "1"
                                                       // b: "2"
    {{- include "base.map" (dict) }}                  // {}
*/ -}}
{{- define "base.map" -}}
  {{- if kindIs "map" . }}
    {{- toYamlPretty . }}
  {{- else }}
    {{- /* 快速失败: 非字典类型立即中断，避免下游 range 失效或类型假设被破坏 */ -}}
    {{- fail (printf "[base.map] expected map, got '%v' (kind: %s)" . (kindOf .)) }}
  {{- end }}
{{- end }}


{{- /*
  布尔类型校验：接受原生布尔值或字面量字符串 "true" / "false"。

  行为:
    - bool 类型: 原样输出
    - 字符串 "true" / "false": 原样输出
    - 其他类型或非 "true"/"false" 字符串: 渲染中断

  入参: 任意值，期望为 bool 或字面量 "true"/"false"
  返回: 布尔字符串（"true" 或 "false"）；非法输入时中断渲染
  错误信息包含具体值与实际类型，便于调试。

  示例:
    {{- include "base.bool" true }}     // true
    {{- include "base.bool" "true" }}   // true
    {{- include "base.bool" "yes" }}    // [base.bool] expected bool or true/false string, got 'yes' (kind: string)
*/ -}}
{{- define "base.bool" -}}
  {{- if kindIs "bool" . }}
    {{- . }}
  {{- else if and (kindIs "string" .) (or (eq . "true") (eq . "false")) }}
    {{- . }}
  {{- else }}
    {{- /* 快速失败: 既非 bool 又非合法字符串，避免下游解析失败 */ -}}
    {{- fail (printf "[base.bool] expected bool or true/false string, got '%v' (kind: %s)" . (kindOf .)) }}
  {{- end }}
{{- end }}


{{- /*
  整数类型校验：接受 int/int64/float64 或整数字符串。

  行为（按入参类型分支）:
    - int / int64: 通过 printf "%d" 转为十进制
    - float64: 通过 printf "%.0f" 转为十进制（四舍五入）
    - 字符串: 必须严格匹配整数正则，原样返回供下游解析
    - 其他类型: 渲染中断

  入参: 任意值，期望为数值类型或整数字符串
  返回: 数字字符串；非法输入时中断渲染
  错误信息包含具体值与实际类型，便于调试。

  示例:
    {{- include "base.int" 42 }}     // 42
    {{- include "base.int" 3.7 }}    // 4
    {{- include "base.int" "100" }}  // 100
    {{- include "base.int" "1.5" }}  // [base.int] expected int/int64, float64, or integer string, got '1.5'
*/ -}}
{{- define "base.int" -}}
  {{- $type := kindOf . }}

  {{- if or (eq $type "int") (eq $type "int64") }}
    {{- /* 整数类型: 直接格式化输出 */ -}}
    {{- printf "%d" . }}
  {{- else if eq $type "float64" }}
    {{- /* 浮点类型: 四舍五入到整数；float64 精度仅 15 位，超出范围会丢失 */ -}}
    {{- printf "%.0f" . }}
  {{- else if eq $type "string" }}
    {{- $const := include "base.env" "" | fromYaml }}
    {{- /* 字符串: 先正则校验再原样返回，避免 Sprig int 静默容错 */ -}}
    {{- if mustRegexMatch $const.TYPES.INT . }}
      {{- . }}
    {{- else }}
      {{- /* 已确定为 string 类型，错误信息省略 kind 避免冗余 */ -}}
      {{- fail (printf "[base.int] expected int/int64, float64, or integer string, got '%v'" .) }}
    {{- end }}
  {{- else }}
    {{- /* 快速失败: 未知类型直接中断 */ -}}
    {{- fail (printf "[base.int] expected int/int64, float64, or integer string, got '%v' (kind: %s)" . $type) }}
  {{- end }}
{{- end }}


{{- /*
  正整数类型校验：接受非负 int/int64/float64 或正整数字符串。

  行为（按入参类型分支）:
    - int / int64 / float64: 必须 >= 0；截断为 int（丢失浮点小数部分）
    - 字符串: 必须匹配 ^\d+$; 通过 atoi 转为 int
    - 其他类型: 渲染中断

  入参: 任意值，期望为非负数值类型或正整数字符串
  返回: int（十进制）；非法输入时中断渲染
  错误信息包含具体值与实际类型，便于调试。

  示例:
    {{- include "base.int.positive" 42 }}    // 42
    {{- include "base.int.positive" 3.7 }}   // 3
    {{- include "base.int.positive" "100" }} // 100
    {{- include "base.int.positive" -1 }}    // [base.int.positive] expected non-negative int/int64/float64, got '-1' (kind: int)
    {{- include "base.int.positive" "abc" }} // [base.int.positive] expected positive integer string, got 'abc'
*/ -}}
{{- define "base.int.positive" -}}
  {{- $type := kindOf . }}

  {{- if or (eq $type "int") (eq $type "int64") (eq $type "float64") }}
    {{- /* float64 精度仅 15 位，超出范围会四舍五入；此处强转为 int 会丢失小数位 */ -}}
    {{- /* 若需要原样返回，定义时使用双引号字符串即可 */ -}}
    {{- if ge (int .) 0 }}
      {{- int . }}
    {{- else }}
      {{- fail (printf "[base.int.positive] expected non-negative int/int64/float64, got '%v' (kind: %s)" . $type) }}
    {{- end }}
  {{- else if eq $type "string" }}
    {{- $const := include "base.env" "" | fromYaml }}
    {{- /* 字符串: 先正则校验再 atoi，避免非法输入被静默吞掉 */ -}}
    {{- if mustRegexMatch $const.TYPES.POSITIVE_INT . }}
      {{- atoi . }}
    {{- else }}
      {{- /* 已确定为 string 类型，错误信息省略 kind 避免冗余 */ -}}
      {{- fail (printf "[base.int.positive] expected positive integer string, got '%v'" .) }}
    {{- end }}
  {{- else }}
    {{- /* 快速失败: 未知类型直接中断 */ -}}
    {{- fail (printf "[base.int.positive] expected non-negative int/int64/float64 or positive integer string, got '%v' (kind: %s)" . $type) }}
  {{- end }}
{{- end }}


{{- /*
  字符串类型校验：先 trim、后正则匹配，trim 后为空则快速失败。

  行为:
    - 非字符串类型: 渲染中断
    - trim 后空字符串: 渲染中断（避免空值穿透）
    - 匹配 TYPES.ZERO（如 "0000"、"-007"）: 折叠为单一前导零
    - 匹配 TYPES.OCTAL_HEX（如 "0x1F"、"0o755"）: 原样返回
    - 其他字符串: trim 后原样返回

  入参: 任意值，期望为非空字符串
  返回: 字符串；非法输入或 trim 后为空时中断渲染
  错误信息包含具体值；已确定为 string 类型时省略 kind，避免暴露底层细节。

  示例:
    {{- include "base.string" "0000" }}   // 0
    {{- include "base.string" "-007" }}   // -07
    {{- include "base.string" "0x1F" }}   // 0x1F
    {{- include "base.string" "  abc " }} // abc
    {{- include "base.string" "  0000  " }} // 0 (关键修复: 先 trim 再校验零模式)
    {{- include "base.string" 42 }}       // [base.string] expected string, got '42' (kind: int)
    {{- include "base.string" "   " }}    // [base.string] expected non-empty string
*/ -}}
{{- define "base.string" -}}
  {{- /* 步骤1: 拦截非字符串类型 */ -}}
  {{- if not (kindIs "string" .) }}
    {{- fail (printf "[base.string] expected string, got '%v' (kind: %s)" . (kindOf .)) }}
  {{- end }}

  {{- /* 步骤2: 先 trim 消除首尾空白，避免空白干扰正则匹配与零折叠 */ -}}
  {{- $trimmed := trim . }}

  {{- /* 步骤3: trim 后空字符串快速失败（已确定为 string，错误信息省略 kind） */ -}}
  {{- if eq $trimmed "" }}
    {{- fail "[base.string] expected non-empty string" }}
  {{- end }}

  {{- $const := include "base.env" "" | fromYaml }}

  {{- /* 步骤4: 零模式匹配（可选符号 + 一个或多个 0 + 可选尾随数字），折叠为单一前导零 */ -}}
  {{- if mustRegexMatch $const.TYPES.ZERO $trimmed }}
    {{- mustRegexReplaceAll $const.TYPES.ZERO $trimmed "${1}0${2}" }}
  {{- /* 步骤5: 八进制/十六进制前缀直通（"0x..." / "0o..."） */ -}}
  {{- else if mustRegexMatch $const.TYPES.OCTAL_HEX $trimmed }}
    {{- $trimmed }}
  {{- /* 步骤6: 默认原样返回（已 trim） */ -}}
  {{- else }}
    {{- $trimmed }}
  {{- end }}
{{- end }}


{{- /*
  切片类型校验：空切片合法且渲染为 "[]"。

  行为:
    - 切片类型: 使用 toYamlPretty 渲染
    - 非切片类型: 渲染中断

  入参: 任意值，期望为切片
  返回: YAML 字符串；非切片输入时中断渲染
  错误信息包含具体值与实际类型，便于调试。

  示例:
    {{- include "base.slice" (list "a" "b" "c") }}  // - a
                                                     // - b
                                                     // - c
    {{- include "base.slice" (list) }}              // []
*/ -}}
{{- define "base.slice" -}}
  {{- if kindIs "slice" . }}
    {{- toYamlPretty . }}
  {{- else }}
    {{- /* 快速失败: 非切片类型直接中断，避免下游 range 失效 */ -}}
    {{- fail (printf "[base.slice] expected slice, got '%v' (kind: %s)" . (kindOf .)) }}
  {{- end }}
{{- end }}
