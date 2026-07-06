{{- /*
  base.get - 从多层上下文统一、安全取值，类型转换与合并
  功能：按点分路径遍历上下文，合并多数据源值，支持强制类型转换、合并模式控制、必填校验与调试日志
  入参：list <上下文> <点分路径> [强制类型] [合并模式] [必填校验布尔] [调试布尔]
    - index 0: 根上下文(any)，必填，通常为 .
    - index 1: 点分取值路径(string)，必填，如 "image.repository"
    - index 2: 强制类型(string)，可选，int/int64/float64/atoi/toString/toStrings/toDecimal/quote/squote
    - index 3: 合并模式(string)，可选，字典: left(默认)/right；列表: concat(默认)/replace
    - index 4: 必填校验(bool)，可选，默认 false
    - index 5: 调试日志(bool)，可选，默认 false
  返回值：toYaml 处理后的 YAML 字符串，配合 fromYaml 使用
  优先级：上下文自身 > .Context > .Values > .Values.global
  示例：
    {{- $val := include "base.get" (list . "image.repository") | fromYaml }}
    {{- $replicas := include "base.get" (list . "replicas" "int") | fromYaml }}
    {{- $name := include "base.get" (list . "name" "" "" true) | fromYaml }}
*/ -}}
{{- define "base.get" -}}
{{- /* 1. 参数校验 */ -}}
{{- if or (not (kindIs "slice" .)) (lt (len .) 2) -}}
  {{- fail (printf "[base.get] 参数: 必须为列表且至少 2 个参数，格式: list <上下文> <点分路径> [强制类型] [合并模式] [必填校验] [调试]，实际长度: %d" (len .)) -}}
{{- end -}}

{{- $root := index . 0 -}}
{{- $key := index . 1 -}}
{{- $forceType := "" -}}
{{- $mergeMode := "left" -}}
{{- $isRequired := false -}}
{{- $isDebug := false -}}

{{- if gt (len .) 2 -}}
  {{- $ft := index . 2 -}}
  {{- if $ft -}}
    {{- $forceType = $ft -}}
  {{- end -}}
{{- end -}}
{{- if gt (len .) 3 -}}
  {{- $mm := index . 3 -}}
  {{- if $mm -}}
    {{- $mergeMode = $mm -}}
  {{- end -}}
{{- end -}}
{{- if gt (len .) 4 -}}
  {{- $req := index . 4 -}}
  {{- if kindIs "bool" $req -}}
    {{- $isRequired = $req -}}
  {{- end -}}
{{- end -}}
{{- if gt (len .) 5 -}}
  {{- $dbg := index . 5 -}}
  {{- if kindIs "bool" $dbg -}}
    {{- $isDebug = $dbg -}}
  {{- end -}}
{{- end -}}

{{- /* 2. 参数合法性校验 */ -}}
{{- $validTypes := list "int" "int64" "float64" "atoi" "toString" "toStrings" "toDecimal" "quote" "squote" -}}
{{- if and $forceType (not (has $forceType $validTypes)) -}}
  {{- fail (printf "[base.get] 强制类型: 无效值 '%s'，可选: int/int64/float64/atoi/toString/toStrings/toDecimal/quote/squote" $forceType) -}}
{{- end -}}
{{- $validMergeModes := list "left" "right" "concat" "replace" -}}
{{- if not (has $mergeMode $validMergeModes) -}}
  {{- fail (printf "[base.get] 合并模式: 无效值 '%s'，可选: left/right/concat/replace" $mergeMode) -}}
{{- end -}}

{{- /* 3. 分割点分路径 */ -}}
{{- $parts := splitList "." $key -}}
{{- $partsLen := len $parts -}}

{{- if $isDebug -}}
  {{- printf "[base.get DEBUG] key=%s, parts=%v, partsLen=%d, forceType=%s, mergeMode=%s, required=%v" $key $parts $partsLen $forceType $mergeMode $isRequired | nindent 0 -}}
{{- end -}}

{{- /* 4. 逐段遍历：对每个路径段，依次处理 4 个数据源 */ -}}
{{- /* 使用 dict 作为可变状态容器，解决 Go template range 作用域问题 */ -}}
{{- /* 优先级（高→低）：direct(0) > Context(1) > Values(2) > global(3) */ -}}
{{- $st := dict "val" (list nil nil nil nil) "ok" (list false false false false) -}}
{{- $prev := list $root (get $root "Context" | default dict) (get $root "Values" | default dict) (get (get $root "Values" | default dict) "global" | default dict) -}}
{{- $srcNames := list "direct" "Context" "Values" "global" -}}
{{- range $i := until $partsLen -}}
  {{- $part := index $parts $i -}}
  {{- $newVals := list nil nil nil nil -}}
  {{- $newOk := list false false false false -}}
  {{- range $si, $src := $prev -}}
    {{- $prevOk := index ($st.ok) $si -}}
    {{- if eq $i 0 -}}
      {{- /* 第一段：直接从数据源读取 */ -}}
      {{- if hasKey $src $part -}}
        {{- $newVals = list -}}
        {{- range $j := until 4 -}}
          {{- if eq $j $si -}}
            {{- $newVals = append $newVals (index $src $part) -}}
          {{- else -}}
            {{- $newVals = append $newVals (index $newVals $j) -}}
          {{- end -}}
        {{- end -}}
        {{- $newOk = list -}}
        {{- range $j := until 4 -}}
          {{- if eq $j $si -}}
            {{- $newOk = append $newOk true -}}
          {{- else -}}
            {{- $newOk = append $newOk (index $newOk $j) -}}
          {{- end -}}
        {{- end -}}
      {{- end -}}
    {{- else -}}
      {{- /* 后续段：从上一段的遍历结果中取值 */ -}}
      {{- if $prevOk -}}
        {{- $prevVal := index ($st.val) $si -}}
        {{- if and (eq (kindOf $prevVal) "map") (hasKey $prevVal $part) -}}
          {{- $newVals = list -}}
          {{- range $j := until 4 -}}
            {{- if eq $j $si -}}
              {{- $newVals = append $newVals (index $prevVal $part) -}}
            {{- else -}}
              {{- $newVals = append $newVals (index $newVals $j) -}}
            {{- end -}}
          {{- end -}}
          {{- $newOk = list -}}
          {{- range $j := until 4 -}}
            {{- if eq $j $si -}}
              {{- $newOk = append $newOk true -}}
            {{- else -}}
              {{- $newOk = append $newOk (index $newOk $j) -}}
            {{- end -}}
          {{- end -}}
        {{- end -}}
      {{- end -}}
    {{- end -}}
    {{- if $isDebug -}}
      {{- printf "[base.get DEBUG] seg=%s, src=%s, ok=%v, val=%v" $part (index $srcNames $si) (index $newOk $si) (index $newVals $si) | nindent 0 -}}
    {{- end -}}
  {{- end -}}
  {{- /* 更新状态，供下一段使用 */ -}}
  {{- $_ := set $st "val" $newVals -}}
  {{- $_ = set $st "ok" $newOk -}}
  {{- /* 更新 $prev：第一段后切换为中间结果值 */ -}}
  {{- if eq $i 0 -}}
    {{- $prev = $newVals -}}
  {{- end -}}
{{- end -}}

{{- /* 5. 合并各数据源的值 */ -}}
{{- $v0 := index ($st.val) 0 -}}
{{- $v1 := index ($st.val) 1 -}}
{{- $v2 := index ($st.val) 2 -}}
{{- $v3 := index ($st.val) 3 -}}
{{- $ok0 := index ($st.ok) 0 -}}
{{- $ok1 := index ($st.ok) 1 -}}
{{- $ok2 := index ($st.ok) 2 -}}
{{- $ok3 := index ($st.ok) 3 -}}

{{- $finalRes := "" -}}
{{- $finalSet := false -}}

{{- /* 按优先级找到最高优先级的有效值类型 */ -}}
{{- $topType := "" -}}
{{- range $k, $v := (list (list $v0 $ok0) (list $v1 $ok1) (list $v2 $ok2) (list $v3 $ok3)) -}}
  {{- if and (not $topType) (index $v 1) -}}
    {{- $topType = kindOf (index $v 0) -}}
  {{- end -}}
{{- end -}}

{{- if eq $topType "map" -}}
  {{- /* 字典合并：从高优先级到低优先级合并 */ -}}
  {{- /* left 模式：mustMerge 左优，高优先级在左，已有键不被覆盖 */ -}}
  {{- /* right 模式：mustMergeOverwrite 右优，低优先级在右，覆盖高优先级 */ -}}
  {{- $res := dict -}}
  {{- if and $ok0 (eq (kindOf $v0) "map") -}}
    {{- $res = mustMerge $res $v0 -}}
  {{- end -}}
  {{- if and $ok1 (eq (kindOf $v1) "map") -}}
    {{- if eq $mergeMode "right" -}}
      {{- $res = mustMergeOverwrite $res $v1 -}}
    {{- else -}}
      {{- $res = mustMerge $res $v1 -}}
    {{- end -}}
  {{- end -}}
  {{- if and $ok2 (eq (kindOf $v2) "map") -}}
    {{- if eq $mergeMode "right" -}}
      {{- $res = mustMergeOverwrite $res $v2 -}}
    {{- else -}}
      {{- $res = mustMerge $res $v2 -}}
    {{- end -}}
  {{- end -}}
  {{- if and $ok3 (eq (kindOf $v3) "map") -}}
    {{- if eq $mergeMode "right" -}}
      {{- $res = mustMergeOverwrite $res $v3 -}}
    {{- else -}}
      {{- $res = mustMerge $res $v3 -}}
    {{- end -}}
  {{- end -}}
  {{- $finalRes = $res -}}
  {{- $finalSet = true -}}
{{- else if eq $topType "slice" -}}
  {{- if eq $mergeMode "replace" -}}
    {{- /* 全量替换：取第一个非空列表（按优先级） */ -}}
    {{- range $k, $v := (list (list $v0 $ok0) (list $v1 $ok1) (list $v2 $ok2) (list $v3 $ok3)) -}}
      {{- if and (not $finalSet) (index $v 1) (eq (kindOf (index $v 0)) "slice") (gt (len (index $v 0)) 0) -}}
        {{- $finalRes = index $v 0 -}}
        {{- $finalSet = true -}}
      {{- end -}}
    {{- end -}}
  {{- else -}}
    {{- /* concat：拼接去重 */ -}}
    {{- $accum := list -}}
    {{- $seen := dict -}}
    {{- range $k, $v := (list (list $v0 $ok0) (list $v1 $ok1) (list $v2 $ok2) (list $v3 $ok3)) -}}
      {{- if and (index $v 1) (eq (kindOf (index $v 0)) "slice") -}}
        {{- range $item := (index $v 0) -}}
          {{- $itemKey := toString $item -}}
          {{- if not (hasKey $seen $itemKey) -}}
            {{- $accum = append $accum $item -}}
            {{- $_ := set $seen $itemKey true -}}
          {{- end -}}
        {{- end -}}
      {{- end -}}
    {{- end -}}
    {{- $finalRes = $accum -}}
    {{- $finalSet = true -}}
  {{- end -}}
{{- else -}}
  {{- /* 基础类型：取第一个非空值（按优先级） */ -}}
  {{- range $k, $v := (list (list $v0 $ok0) (list $v1 $ok1) (list $v2 $ok2) (list $v3 $ok3)) -}}
    {{- if and (not $finalSet) (index $v 1) -}}
      {{- $val := index $v 0 -}}
      {{- $vt := kindOf $val -}}
      {{- $isValid := true -}}
      {{- if eq $vt "string" -}}
        {{- if eq $val "" -}}
          {{- $isValid = false -}}
        {{- end -}}
      {{- end -}}
      {{- if $isValid -}}
        {{- $finalRes = $val -}}
        {{- $finalSet = true -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
{{- end -}}

{{- /* 6. 强制类型转换 */ -}}
{{- if and $finalSet $forceType -}}
  {{- if eq $forceType "int" -}}
    {{- $finalRes = int $finalRes -}}
  {{- else if eq $forceType "int64" -}}
    {{- $finalRes = int64 $finalRes -}}
  {{- else if eq $forceType "float64" -}}
    {{- $finalRes = float64 $finalRes -}}
  {{- else if eq $forceType "atoi" -}}
    {{- $finalRes = atoi $finalRes -}}
  {{- else if eq $forceType "toString" -}}
    {{- $finalRes = print $finalRes -}}
  {{- else if eq $forceType "toStrings" -}}
    {{- $finalRes = toStrings $finalRes -}}
  {{- else if eq $forceType "toDecimal" -}}
    {{- $finalRes = toDecimal $finalRes -}}
  {{- else if eq $forceType "quote" -}}
    {{- $finalRes = quote $finalRes -}}
  {{- else if eq $forceType "squote" -}}
    {{- $finalRes = squote $finalRes -}}
  {{- end -}}
{{- end -}}

{{- /* 7. 必填校验：值未找到时立即中断报错 */ -}}
{{- if and $isRequired (not $finalSet) -}}
  {{- fail (printf "[base.get] %s: 必填" $key) -}}
{{- end -}}

{{- /* 8. 输出 */ -}}
{{- if $isDebug -}}
  {{- printf "[base.get DEBUG] finalRes=%v, finalSet=%v" $finalRes $finalSet | nindent 0 -}}
{{- else if $finalSet -}}
  {{- toYaml $finalRes -}}
{{- end -}}
{{- end }}
