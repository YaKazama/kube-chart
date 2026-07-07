{{- /*
  统一取值函数：从多层上下文安全取值，支持点分路径、类型转换、集合合并与必填校验。

  入参: list <上下文> <点分路径> [强制类型] [合并模式] [必填校验] [调试]
    上下文     根上下文（通常为 `.`），必填
    点分路径   支持多级嵌套（如 image.repository），必填
    强制类型   int | int64 | float64 | atoi | toString | toStrings | toDecimal | quote | squote
    合并模式   字典: left 左优(默认) | right 右优；列表: concat 拼接去重(默认) | replace 全量替换
    必填校验   true 时取值为空立即报错，默认 false
    调试       true 时输出调试日志，默认 false

  返回值: toYamlPretty 格式化后的 YAML 字符串，配合 fromYaml 使用

  取值优先级: 上下文自身 > .Context > .Values > .Values.global

  示例:
    {{- $val := include "base.get" (list . "image.repository") | fromYaml }}
    {{- $repo := include "base.get" (list . "image.repository" "toString" "" true) | fromYaml }}
    {{- $labels := include "base.get" (list . "labels" "" "right") | fromYaml }}
*/ -}}
{{- define "base.get" -}}
  {{- /* Step 1: 参数校验 */}}
  {{- if not (kindIs "slice" .) }}
    {{- fail "[base.get] parameter must be slice type" }}
  {{- end }}
  {{- if lt (len .) 2 }}
    {{- fail (printf "[base.get] at least 2 parameters required (context, dot-path), got '%d'" (len .)) }}
  {{- end }}

  {{- /* Step 2: 解析参数 */}}
  {{- $root := index . 0 }}
  {{- $keyPath := index . 1 }}
  {{- $type := "" }}
  {{- $mergeMode := "left" }}
  {{- $required := false }}
  {{- $debug := false }}

  {{- if ge (len .) 3 }}
    {{- $type = index . 2 }}
  {{- end }}
  {{- if ge (len .) 4 }}
    {{- $mergeMode = index . 3 }}
  {{- end }}
  {{- if ge (len .) 5 }}
    {{- $required = index . 4 }}
  {{- end }}
  {{- if ge (len .) 6 }}
    {{- $debug = index . 5 }}
  {{- end }}

  {{- /* Step 3: 点分路径拆解 */}}
  {{- $keys := splitList "." $keyPath }}

  {{- if $debug }}
    {{- printf "DEBUG[base.get]: keyPath='%s', keys='%v', type='%s', mergeMode='%s', required='%v'\n" $keyPath $keys $type $mergeMode $required }}
  {{- end }}

  {{- /* Step 4: 初始化状态变量 */}}
  {{- $res := "" }}
  {{- $slices := list }}
  {{- $maps := dict }}
  {{- $firstType := "" }}
  {{- $done := false }}

  {{- /* Step 5: 构建数据源列表（优先级从高到低）。数据源: 上下文自身 > .Context > .Values > .Values.global */}}
  {{- $direct := $root }}
  {{- $ctx := dict }}
  {{- $values := dict }}
  {{- $global := dict }}

  {{- if kindIs "map" $root }}
    {{- $ctx = get $root "Context" | default dict }}
    {{- $values = get $root "Values" | default dict }}
    {{- if kindIs "map" $values }}
      {{- $global = get $values "global" | default dict }}
    {{- end }}
  {{- end }}
  {{- $sources := list $direct $ctx $values $global }}

  {{- /* Step 6: 遍历数据源，按优先级取值并合并 */}}
  {{- range $sources }}
    {{- if $done }}
      {{- continue }}
    {{- end }}

    {{- /* 6.1 嵌套路径取值 */}}
    {{- $val := . }}
    {{- $isMissing := false }}
    {{- range $k := $keys }}
      {{- if not $isMissing }}
        {{- if kindIs "map" $val }}
          {{- if hasKey $val $k }}
            {{- $val = get $val $k }}
          {{- else }}
            {{- $isMissing = true }}
          {{- end }}
        {{- else }}
          {{- $isMissing = true }}
        {{- end }}
      {{- end }}
    {{- end }}

    {{- /* 6.2 跳过路径缺失 */}}
    {{- if $isMissing }}
      {{- continue }}
    {{- end }}

    {{- if $debug }}
      {{- printf "DEBUG[base.get]: source='%v', nested val='%v' (kind='%s')\n" . $val (kindOf $val) }}
    {{- end }}

    {{- /* 6.3 类型分类 */}}
    {{- $currentType := "" }}
    {{- if kindIs "map" $val }}
      {{- $currentType = "map" }}
    {{- else if kindIs "slice" $val }}
      {{- $currentType = "slice" }}
    {{- else }}
      {{- $currentType = "basic" }}
    {{- end }}

    {{- /* 6.4 处理第一个有效值 */}}
    {{- if not $firstType }}
      {{- if eq $currentType "basic" }}
        {{- if and (kindIs "string" $val) (eq $val "") }}
          {{- continue }}
        {{- end }}
        {{- $res = $val }}
        {{- $firstType = "basic" }}
        {{- $done = true }}
        {{- if $debug }}
          {{- printf "DEBUG[base.get]: basic type assigned: res='%v'\n" $res }}
        {{- end }}
      {{- else if eq $currentType "slice" }}
        {{- $slices = mustDeepCopy $val }}
        {{- $firstType = "slice" }}
        {{- if $debug }}
          {{- printf "DEBUG[base.get]: slice type assigned: slices='%v'\n" $slices }}
        {{- end }}
      {{- else if eq $currentType "map" }}
        {{- $maps = mustDeepCopy $val }}
        {{- $firstType = "map" }}
        {{- if $debug }}
          {{- printf "DEBUG[base.get]: map type assigned: maps='%v'\n" $maps }}
        {{- end }}
      {{- end }}

    {{- /* 6.5 处理后续同类型值（合并模式） */}}
    {{- else if eq $currentType $firstType }}
      {{- if eq $currentType "slice" }}
        {{- if gt (len $val) 0 }}
          {{- if eq $mergeMode "replace" }}
            {{- $slices = mustDeepCopy $val }}
          {{- else }}
            {{- $slices = concat $slices $val | uniq }}
          {{- end }}
          {{- if $debug }}
            {{- printf "DEBUG[base.get]: slice merged: slices='%v'\n" $slices }}
          {{- end }}
        {{- end }}
      {{- else if eq $currentType "map" }}
        {{- if gt (len $val) 0 }}
          {{- if eq $mergeMode "right" }}
            {{- $maps = mustMergeOverwrite $maps (mustDeepCopy $val) }}
          {{- else }}
            {{- $maps = mustMerge $maps (mustDeepCopy $val) }}
          {{- end }}
          {{- if $debug }}
            {{- printf "DEBUG[base.get]: map merged: maps='%v'\n" $maps }}
          {{- end }}
        {{- end }}
      {{- end }}
    {{- end }}
  {{- end }}

  {{- /* Step 7: 必填校验 */}}
  {{- if $required }}
    {{- $isEmpty := true }}
    {{- if eq $firstType "basic" }}
      {{- $isEmpty = false }}
      {{- if and (kindIs "string" $res) (eq $res "") }}
        {{- $isEmpty = true }}
      {{- end }}
    {{- else if eq $firstType "slice" }}
      {{- if gt (len $slices) 0 }}
        {{- $isEmpty = false }}
      {{- end }}
    {{- else if eq $firstType "map" }}
      {{- if gt (len $maps) 0 }}
        {{- $isEmpty = false }}
      {{- end }}
    {{- end }}
    {{- if $isEmpty }}
      {{- fail (printf "[base.get] '%s': required field is missing or empty" $keyPath) }}
    {{- end }}
  {{- end }}

  {{- /* Step 8: 类型转换 */}}
  {{- $finalType := $firstType }}
  {{- if and $type (eq $type "toStrings") }}
    {{- if eq $finalType "basic" }}
      {{- $slices = list (toString $res) }}
      {{- $finalType = "slice" }}
    {{- else if eq $finalType "slice" }}
      {{- $slices = toStrings $slices }}
    {{- end }}
  {{- else if eq $firstType "basic" }}
    {{- if eq $type "int" }}
      {{- $res = int $res }}
    {{- else if eq $type "int64" }}
      {{- $res = int64 $res }}
    {{- else if eq $type "float64" }}
      {{- $res = float64 $res }}
    {{- else if eq $type "atoi" }}
      {{- $res = atoi $res }}
    {{- else if eq $type "toString" }}
      {{- $res = toString $res }}
    {{- else if eq $type "toDecimal" }}
      {{- $res = toDecimal $res }}
    {{- else if eq $type "quote" }}
      {{- $res = quote $res }}
    {{- else if eq $type "squote" }}
      {{- $res = squote $res }}
    {{- end }}
  {{- end }}

  {{- if $debug }}
    {{- printf "DEBUG[base.get]: finalType='%s', res='%v', slices='%v', maps='%v'\n" $finalType $res $slices $maps }}
  {{- end }}

  {{- /* Step 9: 返回 toYamlPretty 格式化结果 */}}
  {{- if eq $finalType "basic" }}
    {{- toYamlPretty $res }}
  {{- else if eq $finalType "slice" }}
    {{- toYamlPretty $slices }}
  {{- else if eq $finalType "map" }}
    {{- toYamlPretty $maps }}
  {{- else }}
    {{- "" }}
  {{- end }}
{{- end }}
