{{- /*
  从传入的上下文中取指定 key 的值
  优先级: 上下文自身 > .Context > .Values > .Values.global
  参数:
    - index 0: list 上下文(any)
    - index 1: 目标键名(string)
    - index 2: 强制类型(int|int64|float64|atoi|toString|toStrings|toDecimal)
      - 特殊：若此值为 "debug" 则会输出 DEBUG 信息

  可以处理的数据类型包括：
  - 常规类型 string / float64 / int / int64 / bool
  - 切片类型 slice / array
  - map 类型 map / object

  注意：
    - 最顶层的上下文包括的 Keys: Chart Files Capabilities Values Subcharts Template Release Context
      - Context 是自定义追加的
    - base.getValue 只能从当前上下文、Context、Values、Values.global 中取值，其他字段无法处理
*/ -}}
{{- define "base.getValue" -}}
  {{- if or (not (kindIs "slice" .)) (lt (len .) 2) }}
    {{- fail (printf "base.getValue: Must be a slice and requires 2-3 parameters. format: '[]any{ctx(any) key(string) type(string, choices: int|int64|float64|atoi|toString|toStrings|toDecimal)}', values: '%s'" .) }}
  {{- end }}

  {{- $root := index . 0 }}
  {{- $key := index . 1 }}
  {{- $newType := "" }}
  {{- $isDebug := false }}
  {{- if eq (len .) 3 }}
    {{- $newType = index . 2 }}
    {{- if eq $newType "debug" }}
      {{- $isDebug = true }}
    {{- end }}
  {{- end }}

  {{- /* 按优先级读取数据源（高优先级覆盖低优先级） */ -}}
  {{- /* 取值顺序: 上下文自身 > .Context > .Values > .Values.global */ -}}
  {{- $directVal := get $root $key }}
  {{- $ctx := get $root "Context" | default dict }}
  {{- $ctxVal := get $ctx $key }}
  {{- $values := get $root "Values" | default dict }}
  {{- $valVal := get $values $key }}
  {{- $global := get $values "global" | default dict }}
  {{- $gloVal := get $global $key }}
  {{- $sources := list $directVal $ctxVal $valVal $gloVal }}

  {{- if $isDebug }}
    {{- printf "DEBUG1: $key=%v, $newType=%v, $sources=%v, sources len=%d" $key $newType $sources (len $sources) | print | nindent 0 }}
  {{- end }}

  {{- /* 初始化变量 */ -}}
  {{- $basicTypes := list "string" "float64" "int" "int64" "bool" }}
  {{- $res := "" }}
  {{- $slices := list }}
  {{- $maps := dict }}
  {{- $firstType := "" }}
  {{- $done := false }}

  {{- range $sources }}
    {{- if $done }}
      {{- continue }}
    {{- end }}

    {{- $valType := kindOf . }}
    {{- $currentType := "" }}

    {{- /* 1. 类型分类：保留原有逻辑 */}}
    {{- if has $valType $basicTypes }}
      {{- $currentType = "basic" }}
    {{- else if eq $valType "slice" }}
      {{- $currentType = "slice" }}
    {{- else if eq $valType "map" }}
      {{- $currentType = "map" }}
    {{- end }}

    {{- if $isDebug }}
      {{- printf "DEBUG2: $val=%v, $valType=%v $currentType=%v" . $valType $currentType | nindent 0 }}
    {{- end }}

    {{- /* 2. 处理目标类型：过滤空字符串 "" */}}
    {{- if $currentType }}
      {{- /* 处理第一个有效值 */}}
      {{- if not $firstType }}
        {{- /* 基础类型：过滤空字符串""，保留其他有效值 */ -}}
        {{- if eq $currentType "basic" }}
          {{- if not $res }}
            {{- /* 按类型区分空值判断 */ -}}
            {{- $isValid := true }}
            {{- if eq $valType "string" }}
              {{- /* string类型：过滤空字符串 */ -}}
              {{- if eq . "" }}
                {{- $isValid = false }}
              {{- end }}
            {{- end }}

            {{- /* 仅排除 "" 值 */ -}}
            {{- if $isValid }}
              {{- if eq $newType "int" }}
                {{- $res = int . }}
              {{- else if eq $newType "int64" }}
                {{- $res = int64 . }}
              {{- else if eq $newType "float64" }}
                {{- $res = float64 . }}
              {{- else if eq $newType "atoi" }}
                {{- $res = atoi . }}
              {{- else if eq $newType "toString" }}
                {{- $res = print . }}
              {{- else if eq $newType "toStrings" }}
                {{- $res = toStrings . }}
              {{- else if eq $newType "toDecimal" }}
                {{- $res = toDecimal . }}
              {{- else }}
                {{- $res = . }}
              {{- end }}
              {{- $firstType = "basic" }}
              {{- $done = true }}

              {{- if $isDebug }}
                {{- printf "DEBUG3: 基础类型赋值成功: $res=%v, $valType=%v" $res $valType | nindent 0 }}
              {{- end }}
            {{- end }}
          {{- end }}
        {{- /* 切片类型：concat 合并 */}}
        {{- else if eq $currentType "slice" }}
          {{- if gt (len .) 0 }}
            {{- $slices = concat $slices . }}
            {{- $firstType = "slice" }}

            {{- if $isDebug }}
              {{- printf "DEBUG3: 切片类型赋值成功: $slices=%v" $slices | nindent 0 }}
            {{- end }}
          {{- end }}
        {{- /* 映射类型：mustMerge 合并 */}}
        {{- else if eq $currentType "map" }}
          {{- if gt (len .) 0 }}
            {{- $maps = mustMerge $maps . }}
            {{- $firstType = "map" }}

            {{- if $isDebug }}
              {{- printf "DEBUG3: 映射类型赋值成功: $maps=%v" $maps | nindent 0 }}
            {{- end }}
          {{- end }}
        {{- end }}
      {{- /* 处理后续值：保留同类型合并逻辑 */}}
      {{- else }}
        {{- if eq $currentType $firstType }}
          {{- /* 基础类型：已取第一个，跳过 */}}
          {{- if eq $currentType "basic" }}
            {{- continue }}
          {{- /* 切片类型：合并非空切片 */}}
          {{- else if eq $currentType "slice" }}
            {{- if gt (len .) 0 }}
              {{- $slices = concat $slices . }}
            {{- end }}
          {{- /* 映射类型：合并非空映射 */}}
          {{- else if eq $currentType "map" }}
            {{- if gt (len .) 0 }}
              {{- $maps = mustMerge $maps . }}
            {{- end }}
          {{- end }}
        {{- end }}
      {{- end }}
    {{- end }}
  {{- end }}

  {{- /* 返回值 */ -}}
  {{- if $isDebug }}
    {{- printf "DEBUG0: $res=%v, $slices=%v, $maps=%v" $res $slices $maps | nindent 0 }}
  {{- else }}
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
{{- end }}
