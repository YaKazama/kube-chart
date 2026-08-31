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

  行为: 仅当非空 slice 的首个元素包含 "error"（忽略大小写）时返回 "true"。

  入参: 任意类型的 fromYamlArray 返回值。

  边界: 只识别 Helm 的 fromYamlArray 错误形态，不解析错误内容。

  返回值: 布尔字符串。

  示例:
    {{- include "base.isFromYamlArrayError" (list "error converting YAML to JSON") }}  // true
    {{- include "base.isFromYamlArrayError" (list "a" "b") }}                        // false
*/ -}}
{{- define "base.isFromYamlArrayError" -}}
  {{- $_val := first . | default "" }}
  {{- and (ne (len .) 0) (or (contains "error" $_val) (contains "Error" $_val)) }}
{{- end }}
