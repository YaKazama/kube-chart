{{- /*
  从传入的上下文中取指定 key 的值
  优先级: 上下文自身 > .Context > .Values > .Values.global
  参数: list 上下文(any) 目标键名(string) 强制类型(string|float64|int|int64|bool)

  可以处理的数据类型包括：
  - 常规类型 string / float64 / int / int64 / bool
  - 切片类型 slice / array
  - map 类型 map / object

*/ -}}
{{- define "base.getValue" -}}
  {{- if or (not (kindIs "slice" .)) (lt (len .) 2) }}
    {{- fail "Must be a slice and requires 2-3 parameters. format: '[]any{ctx(any) key(string) type(string, choices: int|int64|float64|atoi|toString|toStrings|toDecimal)}'" }}
  {{- end }}

  {{- $root := index . 0 }}
  {{- $key := index . 1 }}
  {{- $newType := "" }}
  {{- if eq (len .) 3 }}
    {{- $newType = index . 2 }}
  {{- end }}

  {{- /* 按优先级读取数据源（从低到高排列，高优先级覆盖低优先级） */ -}}
  {{- $directVal := get $root $key | default "" }}

  {{- $ctx := get $root "Context" | default dict }}
  {{- $ctxVal := get $ctx $key | default "" }}

  {{- $values := get $root "Values" | default dict }}
  {{- $valVal := get $values $key | default "" }}

  {{- $global := get $values "global" | default dict }}
  {{- $gloVal := get $global $key | default "" }}

  {{- $sources := list $directVal $ctxVal $valVal $gloVal }}

  {{- /* 初始化变量 */ -}}
  {{- $basicTypes := list "string" "float64" "int" "int64" "bool" }}
  {{- $res := "" }}
  {{- $slices := list }}
  {{- $maps := dict }}

  {{- range $sources }}
    {{- $valType := kindOf . }}
    {{- if has $valType $basicTypes }}
      {{- if not $res }}
        {{- if eq $newType "int" }}
          {{- $res = int . }}
        {{- else if eq $newType "int64" }}
          {{- $res = int64 . }}
        {{- else if eq $newType "float64" }}
          {{- $res = float64 . }}
        {{- else if eq $newType "atoi" }}
          {{- $res = atoi . }}
        {{- else if eq $newType "toString" }}
          {{- $res = toString . }}
        {{- else if eq $newType "toStrings" }}
          {{- $res = toStrings . }}
        {{- else if eq $newType "toDecimal" }}
          {{- $res = toDecimal . }}
        {{- else }}
          {{- $res = . }}
        {{- end }}
      {{- end }}
    {{- else if eq $valType "slice" }}
      {{- $slices = concat $slices . }}
    {{- else if eq $valType "map" }}
      {{- $maps = mustMerge $maps . }}
    {{- end }}
  {{- end }}

  {{- /* 返回值 */ -}}
  {{- if $res }}
    {{- $res }}
  {{- else if $slices }}
    {{- toYamlPretty $slices }}
  {{- else if $maps }}
    {{- toYamlPretty $maps }}
  {{- else }}
    {{- "" }}
  {{- end }}
{{- end }}
