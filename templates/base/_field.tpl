{{- /*
  variables(slice): any[key(string), value(any), define(string)?, allow(slice)?]
    - index 0: key (字符串，必传)
    - index 1: value (任意类型，必传)
    - index 2: define (处理 value 的模板名，可选) / "quote" (是否添加双引号，可选) (quote 是一个特殊的关键字, 同时 define 也会强制设置为 base.string)
    - index 3: allows (允许的值列表，可选) (define 会强制设置为 base.string, 此时 define 传入的値会作为 allows 的默认值)

  提示：
    - 两个参数时， define 默认为 "base.string"
    - 三个参数时， define 可以为任意模板定义名称或 "quote"
    - 四个参数时， define 会强制为 "base.string" (有 allows 的情况，全是 string 类型的数据)

  传值使用示例：
    - key value / key value "base.string"
    - key value "quote"
    - key value "base.string" allowsList

  return: key: value
*/ -}}
{{- define "base.field" -}}
  {{- /* 1. 校验参数类型和长度（恢复为 2 - 4 个参数） */}}
  {{- if not (kindIs "slice" .) }}
    {{- fail "base.field: Must be a slice and requires 2 to 4 parameters. Format: '[key(string), value(any), define(string)?, allows(slice)?, chompFlag(string)?]'" }}
  {{- end }}

  {{- $sliceLen := len . }}

  {{- /* 2. 解析基础参数 */}}
  {{- $key := include "base.string" (index . 0) }}
  {{- $rawValue := index . 1 }}
  {{- $define := "base.string" }}
  {{- $allows := list }}

  {{- /* 3. 解析可选参数（仅 2 - 4 个参数） */}}
  {{- if eq $sliceLen 3 }}
    {{- $define = index . 2 }}
  {{- end }}
  {{- if ge $sliceLen 4 }}
    {{- $allows = index . 3 }}
  {{- end }}

  {{- /* 4. 处理引号逻辑 */}}
  {{- $isQuote := false }}
  {{- if eq $define "quote" }}
    {{- $isQuote = true }}
  {{- end }}
  {{- if or $allows $isQuote }}
    {{- $define = "base.string" }}
  {{- end }}

  {{- /* 获取处理后的值 */}}
  {{- $val := include $define $rawValue }}

  {{- /* 5. 多行字符串判断（兼容Unix/Windows换行符，只判断不修改） */ -}}
  {{- /* 精准判断多行字符串（三步校验） 1. 是字符串类型 2. 非空 3. 包含换行符 */ -}}
  {{- $isMultiLine := false }}
  {{- if kindIs "string" $val }}
    {{- $isMultiLine = and (ne $val "") (or (contains "\n" $val) (contains "\r\n" $val)) }}
  {{- end }}

  {{- /* 6. 处理引号 仅对单行字符串添加引号，多行跳过 */}}
  {{- /* 如果 isQuote = true 将默认值和处理后的值都加双引号 */ -}}
  {{- $finalVal := $val }}
  {{- if and $isQuote (not $isMultiLine) }}
    {{- $finalVal = $finalVal | quote }}
  {{- end }}

  {{- /* 7. 判断是否输出（保留 allows 原有功能） */}}
  {{- /* 输出条件：值非空，且（无 allows 或在 allows 中） */}}
  {{- $shouldOutput := true }}
  {{- if $allows }}
    {{- $shouldOutput = has $finalVal $allows }}
  {{- end }}

  {{- /* 8. 输出逻辑（硬编码块标量标识为 |- ） */}}
  {{- if and $shouldOutput (ne $finalVal "") }}
    {{- /* 辅助判断：是否为切片/映射类型 */}}
    {{- $isMap := or (contains "map" $define) (contains "object" $define) }}
    {{- $isSlice := or (contains "slice" $define) (contains "array" $define) (contains "list" $define) (contains "tuple" $define) }}

    {{- /* 处理sliceLen的不同情况（合并逻辑，简化代码） */}}
    {{- if or $isMap $isSlice }}
      {{- /* 切片/映射：原有换行缩进逻辑 */}}
      {{- nindent 0 "" -}}{{ $key }}:
      {{- $finalVal | nindent 2 }}
    {{- else if $isMultiLine }}
      {{- /* 多行字符串：使用传递的 chompFlag */}}
      {{- /* "|-" 只能硬编码，其他 "|" "|+" ">" ">-" ">+" "|N" 等无效，理论上这个与底层的 YAML 库有关 */ -}}
      {{- nindent 0 "" -}}{{ $key }}: |-
      {{- $finalVal | nindent 2 }}
    {{- else }}
      {{- /* 单行/非字符串：直接输出 */}}
      {{- nindent 0 "" -}}{{ $key }}: {{ $finalVal }}
    {{- end }}
  {{- end }}
{{- end }}
