{{- define "base.chart" -}}
  {{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "base.helmLabels" -}}
  {{- nindent 0 "" -}}helm.sh/chart: {{ include "base.chart" . }}
  {{- nindent 0 "" -}}app.kubernetes.io/version: {{ .Chart.AppVersion }}
  {{- nindent 0 "" -}}app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- /* 修复点：用 get 替代 dig，避免类型转换错误 */}}
{{- define "base.name" -}}
  {{- $name := "" }}

  {{- /* 1. 最高优先级：Context.name */}}
  {{- $ctx := get . "Context" | default dict }}
  {{- $ctxName := get $ctx "name" | default "" }}
  {{- if $ctxName }}
    {{- $name = include "base._extractName" $ctxName }}
  {{- end }}

  {{- /* 2. 次高优先级：Values.name */}}
  {{- if not $name }}
    {{- $values := get . "Values" | default dict }}
    {{- $valName := get $values "name" | default "" }}
    {{- if $valName }}
      {{- $name = include "base._extractName" $valName }}
    {{- end }}
  {{- end }}

  {{- /* 3. 次低优先级：Values.global.name */}}
  {{- if not $name }}
    {{- $values := get . "Values" | default dict }}
    {{- $global := get $values "global" | default dict }}
    {{- $globalName := get $global "name" | default "" }}
    {{- if $globalName }}
      {{- $name = include "base._extractName" $globalName }}
    {{- end }}
  {{- end }}

  {{- /* 4. 最低优先级：Chart.Name */}}
  {{- if not $name }}
    {{- $chart := get . "Chart" | default dict }}
    {{- $name = get $chart "Name" | default "" }}
  {{- end }}

  {{- /* 名称标准化 + RFC1035 验证 */}}
  {{- if not $name }}
    {{- fail "No valid name found in any source (Context/Values/global/Chart)" }}
  {{- end }}
  {{- $name = $name | lower | nospace | trimSuffix "-" }}
  {{- $rfc1035Regex := "^[a-z0-9]([-a-z0-9]*[a-z0-9])?$" }}
  {{- if not (regexMatch $rfc1035Regex $name) }}
    {{- fail (printf "Name '%s' invalid (must match RFC1035: %s)" $name $rfc1035Regex) }}
  {{- end }}

  {{- $name }}
{{- end }}

{{- /* 辅助模板：从 string/slice/map 提取第一个有效字符串 */}}
{{- define "base._extractName" -}}
  {{- $input := . }}
  {{- $extracted := "" }}

  {{- if kindIs "string" $input }}
    {{- $extracted = $input }}
  {{- else if kindIs "slice" $input }}
    {{- range $item := $input }}
      {{- if kindIs "string" $item }}
        {{- $extracted = $item }}
        {{- break }}
      {{- else if kindIs "map" $item }}
        {{- $vals := values $item | sortAlpha }}
        {{- if $vals }}
          {{- $firstVal := index $vals 0 }}
          {{- if kindIs "string" $firstVal }}
            {{- $extracted = $firstVal }}
            {{- break }}
          {{- end }}
        {{- end }}
      {{- end }}
    {{- end }}
  {{- else if kindIs "map" $input }}
    {{- $vals := values $input | sortAlpha }}
    {{- if $vals }}
      {{- $firstVal := index $vals 0 }}
      {{- if kindIs "string" $firstVal }}
        {{- $extracted = $firstVal }}
      {{- end }}
    {{- end }}
  {{- end }}

  {{- if not $extracted }}
    {{- fail (printf "No valid string name in input: %v" $input) }}
  {{- end }}
  {{- $extracted }}
{{- end }}

{{- /* 修复点：移除 dig 函数，改用 get 处理非 map 类型，避免接口转换错误 */}}
{{- define "base.getValWithKey" -}}
  {{- if or (not (kindIs "slice" .)) (ne (len .) 2) }}
    {{- fail "Must be a slice with 2 elements: [rootContext, key]" }}
  {{- end }}

  {{- $root := index . 0 }}  {{/* 根上下文（通常是 Helm 模板中的 .） */}}
  {{- $key := index . 1 }}   {{/* 目标键名（如 "annotations"、"labels"） */}}

  {{- /* 1. 按优先级读取数据源（从高到低） */}}
  {{- /* 最高优先级：Context.key */}}
  {{- $ctx := get $root "Context" | default dict }}  {{/* 即使 Context 不是 map，get 也返回空 dict */}}
  {{- $ctxVal := get $ctx $key | default "" }}

  {{- /* 次高优先级：Values.key */}}
  {{- $values := get $root "Values" | default dict }}
  {{- $valVal := get $values $key | default "" }}

  {{- /* 次低优先级：Values.global.key */}}
  {{- $global := get $values "global" | default dict }}
  {{- $globalVal := get $global $key | default "" }}

  {{- /* 最低优先级：根对象直接取 key */}}
  {{- $directVal := get $root $key | default "" }}

  {{- /* 数据源列表（按优先级从低到高排列，确保高优先级后合并覆盖） */}}
  {{- $sources := list $directVal $globalVal $valVal $ctxVal }}

  {{- /* 2. 提取所有 map 和基本类型 */}}
  {{- $result := "" }}               {{/* 存储基本类型结果 */}}
  {{- $allMaps := list }}            {{/* 存储所有待合并的 map（包括 slice 中的 map） */}}
  {{- $basicTypes := list "string" "float64" "int" "int64" "bool" }}

  {{- range $sources }}
    {{- $val := . }}
    {{- if not $val }}
      {{- continue }}  {{/* 跳过空值 */}}
    {{- end }}

    {{- /* 处理基本类型：取第一个非空的高优先级值 */}}
    {{- if and (not $result) (has (kindOf $val) $basicTypes) }}
      {{- $result = $val }}
    {{- end }}

    {{- /* 提取 map（直接的 map 或 slice 中的 map） */}}
    {{- if kindIs "map" $val }}
      {{- $allMaps = append $allMaps $val }}
    {{- else if kindIs "slice" $val }}
      {{- range $item := $val }}
        {{- if kindIs "map" $item }}
          {{- $allMaps = append $allMaps $item }}
        {{- end }}
      {{- end }}
    {{- end }}
  {{- end }}

  {{- /* 3. 输出结果 */}}
  {{- if $result }}
    {{- $result }}  {{/* 基本类型直接返回 */}}
  {{- else if gt (len $allMaps) 0 }}
    {{- /* 合并所有 map（高优先级覆盖低优先级） */}}
    {{- $mergedMap := dict }}
    {{- range $m := $allMaps }}
      {{- $mergedMap = mustMerge $mergedMap $m }}
    {{- end }}
    {{- toYaml $mergedMap | nindent 2 }}  {{/* 保持缩进一致 */}}
  {{- else }}
    {{- /* 处理纯 slice（非 map 元素） */}}
    {{- $cleanElements := list }}
    {{- range $sources }}
      {{- if kindIs "slice" . }}
        {{- range $e := . }}
          {{- if not (kindIs "map" $e) }}
            {{- $cleanElements = append $cleanElements $e }}
          {{- end }}
        {{- end }}
      {{- end }}
    {{- end }}
    {{- toYaml (uniq (mustCompact $cleanElements)) | nindent 2 }}
  {{- end }}
{{- end }}
