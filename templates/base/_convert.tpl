{{- /*
  float64 转 int（截断小数部分）

  入参: 任意类型，期望为 float64
  返回值: int 的十进制字符串表示；入参非 float64 时中断渲染并报错

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
  bool 转 string

  入参: 任意类型，期望为 bool
  返回值: "true" 或 "false"；入参非 bool 时中断渲染并报错

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
  字符串渲染：空字符串或纯空白字符串输出带引号的空字符串 ""

  入参: string，必填
  返回值:
    - 空字符串 / 纯空白字符串 => ""
    - 非空字符串 => 经 base.string 处理后的原值
  非 string 入参中断渲染并报错

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
  判断字符串是否包含换行符

  入参: string，必填
  返回值: 包含换行符返回 "true"，否则返回 "false"
  非 string 入参中断渲染并报错

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
  保留原始字符串（避免 base.string 破坏多行内容）

  入参: string，必填
  返回值: 原字符串；空字符串 / nil 返回 ""
  非 string 入参中断渲染并报错

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
  判断 fromYaml 返回的是否为错误 map

  入参: 任意类型
  返回值: 是 map 且包含 "Error" 键返回 "true"，否则返回 "false"

  示例:
    {{- include "base.isFromYamlError" (dict "Error" "bad yaml") }}  // true
    {{- include "base.isFromYamlError" (dict "key" "value") }}       // false
*/ -}}
{{- define "base.isFromYamlError" -}}
  {{- and (kindIs "map" .) (hasKey . "Error") }}
{{- end }}


{{- /*
  判断 fromYamlArray 返回的是否为错误 slice

  入参: 任意类型
  返回值: 是 slice、非空且首个元素（字符串）包含 "error" 返回 "true"，否则返回 "false"

  示例:
    {{- include "base.isFromYamlArrayError" (list "error converting YAML to JSON") }}  // true
    {{- include "base.isFromYamlArrayError" (list "a" "b") }}                        // false
*/ -}}
{{- define "base.isFromYamlArrayError" -}}
  {{- if kindIs "slice" . }}
    {{- and (ne (len .) 0) (contains "error" (lower (toString (index . 0)))) }}
  {{- else }}
    {{- false }}
  {{- end }}
{{- end }}
