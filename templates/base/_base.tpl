{{- /*
  从传入的上下文中取指定 key 的值
  优先级: .Context > .Values > .Values.global > 上下文自身
  参数: list 上下文(any) 目标键名(string)

  可以处理的数据类型包括：
  - 常规类型 string / float64 / int / int64 / bool
  - 切片类型 slice / array
  - map 类型 map / object

*/ -}}
{{- define "base.getValue" -}}
  {{- if or (not (kindIs "slice" .)) (ne (len .) 2) }}
    {{- fail "Must be a slice and requires 2 parameters. format: '[ctx(any), key(string)]'" }}
  {{- end }}

  {{- $root := index . 0 }}
  {{- $key := index . 1 }}

  {{- /* 按优先级读取数据源（从低到高排列，高优先级覆盖低优先级） */ -}}
  {{- $ctx := get $root "Context" | default dict }}
  {{- $ctxVal := get $ctx $key | default "" }}

  {{- $values := get $root "Values" | default dict }}
  {{- $valVal := get $values $key | default "" }}

  {{- $global := get $values "global" | default dict }}
  {{- $gloVal := get $global $key | default "" }}

  {{- $directVal := get $root $key | default "" }}

  {{- $sources := list $ctxVal $valVal $gloVal $directVal }}

  {{- /* 初始化变量 */ -}}
  {{- $basicTypes := list "string" "float64" "int" "int64" "bool" }}
  {{- $res := "" }}
  {{- $slices := list }}
  {{- $maps := dict }}

  {{- range $sources }}
    {{- $valType := kindOf . }}
    {{- if has $valType $basicTypes }}
      {{- if not $res }}
        {{- $res = . }}
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
