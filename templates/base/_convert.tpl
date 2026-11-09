{{- /*
  将 float64 转为 int（截断小数部分）。

  行为: 仅接受 float64；其他类型立即中断渲染。

  入参: float64 数值。

  边界: 不执行字符串或其他数值类型的转换。

  返回值: int 的十进制字符串表示。

  示例:
    {{- $n := include "base.ftoi" 3.7 }}   // $n = "3"
    {{- $n := include "base.ftoi" -2.4 }}  // $n = "-2"
*/ -}}
{{- define "base.ftoi" -}}
  {{- if kindIs "float64" . }}
    {{- int . }}
  {{- else }}
    {{- fail (printf "[base.ftoi] expected float64, got '%v' (kind: %s)" . (kindOf .)) }}
  {{- end }}
{{- end }}


{{- /*
  将 bool 转为字符串。

  行为: 仅接受 bool；其他类型立即中断渲染。

  入参: bool 值。

  边界: 不解析 "true"、"false" 等字符串字面量。

  返回值: "true" 或 "false"。

  示例:
    {{- $s := include "base.btoa" true }}   // $s = "true"
    {{- $s := include "base.btoa" false }}  // $s = "false"
*/ -}}
{{- define "base.btoa" -}}
  {{- if kindIs "bool" . }}
    {{- toString . }}
  {{- else }}
    {{- fail (printf "[base.btoa] expected bool, got '%v' (kind: %s)" . (kindOf .)) }}
  {{- end }}
{{- end }}


{{- /*
  渲染允许为空的字符串；空白值输出带引号的空字符串 ""。

  行为:
    - 空字符串 / 纯空白字符串 => ""
    - 非空字符串 => 经 base.string 处理后的原值

  入参: string 值。

  边界: 仅接受 string；非 string 输入立即中断渲染。

  返回值: 适于嵌入 YAML 的字符串。

  示例:
    {{- include "base.string.empty" "" }}       // ""
    {{- include "base.string.empty" "   " }}    // ""
    {{- include "base.string.empty" "hello" }}  // hello
*/ -}}
{{- define "base.string.empty" -}}
  {{- if not (kindIs "string" .) }}
    {{- fail (printf "[base.string.empty] expected string, got '%v' (kind: %s)" . (kindOf .)) }}
  {{- end }}

  {{- $trimmed := . | trim }}
  {{- if empty $trimmed }}
    {{- quote "" }}
  {{- else }}
    {{- include "base.string" . }}
  {{- end }}
{{- end }}


{{- /*
  判断字符串是否包含换行符。

  行为: 仅接受 string；包含 \n 返回 "true"，否则返回 "false"。

  入参: string 值。

  边界: 不识别其他类型或其他空白字符。

  返回值: 布尔字符串。

  示例:
    {{- include "base.isMultiLine" "a\nb" }}  // true
    {{- include "base.isMultiLine" "ab" }}    // false
*/ -}}
{{- define "base.isMultiLine" -}}
  {{- if not (kindIs "string" .) }}
    {{- fail (printf "[base.isMultiLine] expected string, got '%v' (kind: %s)" . (kindOf .)) }}
  {{- end }}
  {{- contains "\n" . -}}
{{- end }}


{{- /*
  保留原始字符串，避免 base.string 改写多行内容。

  行为: 空字符串保留为空；非 string 输入立即中断渲染。

  入参: string 值。

  边界: 不执行 trim、零折叠或其他字符串规范化。

  返回值: 原字符串。

  示例:
    {{- include "base.rawString" "hello" }}  // hello
    {{- include "base.rawString" "" }}      // ""
*/ -}}
{{- define "base.rawString" -}}
  {{- if not (kindIs "string" .) }}
    {{- fail (printf "[base.rawString] expected string, got '%v' (kind: %s)" . (kindOf .)) }}
  {{- end }}
  {{- default "" . -}}
{{- end }}


{{- /*
  判断 fromYaml 返回值是否为错误 map。

  行为: 仅当值为 map 且包含 "Error" 键时返回 "true"。

  入参: 任意类型的 fromYaml 返回值。

  边界: 只识别 Helm 的 fromYaml 错误形态，不解析错误内容。

  返回值: 布尔字符串。

  示例:
    {{- include "base.isFromYamlError" (dict "Error" "bad yaml") }}  // true
    {{- include "base.isFromYamlError" (dict "key" "value") }}       // false
*/ -}}
{{- define "base.isFromYamlError" -}}
  {{- and (kindIs "map" .) (hasKey . "Error") }}
{{- end }}


{{- /*
  判断 fromYamlArray 返回值是否为错误 slice。

  行为: 仅当首个元素转为 string 后包含 "error"（忽略大小写）时返回 "true"。

  入参: `fromYamlArray` 返回值（slice）。

  边界: 只识别 Helm 的 fromYamlArray 错误形态，不解析错误内容；非 slice 输入由 `first` 直接中断渲染。

  返回值: 布尔字符串。

  示例:
    {{- include "base.isFromYamlArrayError" (list "error converting YAML to JSON") }}  // true
    {{- include "base.isFromYamlArrayError" (list "a" "b") }}                        // false
    {{- include "base.isFromYamlArrayError" (list 3 "a") }}                           // false
*/ -}}
{{- define "base.isFromYamlArrayError" -}}
  {{- contains "error" (first . | toString | lower) }}
{{- end }}


{{- /*
  把 YAML 序列化标量文本还原为真实 string 值。

  行为:
    - 入参按单个 YAML 标量解码；解码结果为 string 时返回该值。
    - 空字符串与解码为 null 的文本返回空字符串。
    - 解码失败或结果不是 string 时中断渲染。

  边界:
    - 不做 trim 或其他内容改写，首尾空白与内部换行按解码结果原样返回。
    - 只处理 string 标量；map、array 结构、数值与布尔由调用方选择对应模板。
    - 入参必须是 include 输出的原始文本，调用方不得预先 trim、fromYaml 或拼接。
    - 失败消息使用本模板前缀，不携带调用方字段路径。

  入参: YAML 序列化标量文本。

  返回值: 解码后的 string；空输入返回空字符串。

  示例:
    {{- include "base.string.normalize" "gpu" }}            // gpu
    {{- include "base.string.normalize" "\"on\"" }}         // on
    {{- include "base.string.normalize" "'  spaced  '" }}   // 保留首尾空白
    {{- include "base.string.normalize" "" }}               // 空内容
    {{- include "base.string.normalize" "true" }}           // [base.string.normalize] expected string, got 'true' (kind: bool)
*/ -}}
{{- define "base.string.normalize" -}}
  {{- if not (kindIs "string" .) }}
    {{- fail (printf "[base.string.normalize] parameter: must be string type, got '%v' (kind: %s)" . (kindOf .)) }}
  {{- end }}

  {{- /* 解码一次即可覆盖引号、纯量、块标量与特殊字符；解析失败会得到错误 map，必须先排除才能区分空输入。 */ -}}
  {{- $_decoded := fromYaml (printf "v: %s" .) }}
  {{- if eq (include "base.isFromYamlError" $_decoded) "true" }}
    {{- fail (printf "[base.string.normalize] parameter: not a valid YAML scalar, got '%s'" .) }}
  {{- end }}

  {{- /* 空字符串与 null 均解码为 invalid，统一返回空字符串；其余非 string 类型中断。 */ -}}
  {{- $kind := kindOf $_decoded.v }}
  {{- if eq $kind "invalid" }}
    {{- "" }}
  {{- else if eq $kind "string" }}
    {{- $_decoded.v }}
  {{- else }}
    {{- fail (printf "[base.string.normalize] expected string, got '%v' (kind: %s)" $_decoded.v $kind) }}
  {{- end }}
{{- end }}
