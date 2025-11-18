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

{{- /*
  修复点：
  1. 确保基本类型（bool/string等）直接返回原始值字符串（无YAML格式转换）
  2. 严格区分基本类型与map/slice，避免基本类型被误处理为map输出
  3. 移除基本类型输出时的多余缩进，确保fromYaml正确解析
*/}}
{{- define "base.getValWithKey" -}}
  {{- if or (not (kindIs "slice" .)) (ne (len .) 2) }}
    {{- fail "Must be a slice with 2 elements: [rootContext, key]" }}
  {{- end }}

  {{- $root := index . 0 }}
  {{- $key := index . 1 }}

  {{- /* 1. 按优先级读取数据源 */}}
  {{- $ctx := get $root "Context" | default dict }}
  {{- $ctxVal := get $ctx $key | default "" }}

  {{- $values := get $root "Values" | default dict }}
  {{- $valVal := get $values $key | default "" }}

  {{- $global := get $values "global" | default dict }}
  {{- $globalVal := get $global $key | default "" }}

  {{- $directVal := get $root $key | default "" }}

  {{- /* 数据源按优先级从低到高排列（高优先级后处理） */}}
  {{- $sources := list $directVal $globalVal $valVal $ctxVal }}

  {{- /* 2. 初始化变量 */}}
  {{- $result := "" }}               {{/* 存储基本类型结果 */}}
  {{- $allMaps := list }}            {{/* 存储待合并的map */}}
  {{- $basicTypes := list "string" "float64" "int" "int64" "bool" }}  {{/* 明确包含bool */}}
  {{- $foundBasic := false }}        {{/* 标记是否找到基本类型 */}}

  {{- /* 3. 遍历数据源，提取值 */}}
  {{- range $sources }}
    {{- $val := . }}
    {{- if not $val }}
      {{- /* 空值跳过（替代continue） */}}
    {{- else }}
      {{- /* 处理基本类型：未找到时才检查 */}}
      {{- if not $foundBasic }}
        {{- $valType := kindOf $val }}
        {{- if has $valType $basicTypes }}
          {{- $result = $val }}
          {{- $foundBasic = true }}
        {{- end }}
      {{- end }}

      {{- /* 提取map（包括slice中的map） */}}
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
  {{- end }}

  {{- /* 4. 输出结果（关键修复：基本类型直接返回原始值，不经过toYaml） */}}
  {{- if $result }}
    {{- $result }}  {{/* 直接输出基本类型原始值（如"true"/"false"/"abc"） */}}
  {{- else if gt (len $allMaps) 0 }}
    {{- /* 合并map并转为YAML */}}
    {{- $mergedMap := dict }}
    {{- range $m := $allMaps }}
      {{- $mergedMap = mustMerge $mergedMap $m }}
    {{- end }}
    {{- toYaml $mergedMap | nindent 2 }}  {{/* map类型用YAML格式输出 */}}
  {{- else }}
    {{- "" }}
  {{- end }}
{{- end }}
