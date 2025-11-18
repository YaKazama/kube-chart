{{- define "base.chart" -}}
  {{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "base.helmLabels" -}}
  {{- nindent 0 "" -}}helm.sh/chart: {{ include "base.chart" . }}
  {{- nindent 0 "" -}}app.kubernetes.io/version: {{ .Chart.AppVersion }}
  {{- nindent 0 "" -}}app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "base.name" -}}
  {{- $name := "" }}

  {{- if kindIs "string" . }}
    {{- $name = . }}
  {{- else if kindIs "map" . }}
    {{- /* 从多来源获取 "fullname" 和 "name"（优先 fullname） */ -}}
    {{- $fullnameVal := include "base.getValWithKey" (list . "fullname") | default "" }}
    {{- $nameVal := include "base.getValWithKey" (list . "name") | default "" }}
    {{- $name = coalesce $fullnameVal $nameVal }}
    {{- $isMap := kindIs "map" (fromYaml $name) }}

    {{- /* 从 Chart 名称 fallback（次于 Values.global） */ -}}
    {{- if not $name }}
      {{- if .Chart }}
        {{- $name = .Chart.Name | default "" }}
      {{- end }}
    {{- end }}

    {{- /* 最终 fallback：从 map 值中取第一个字符串（确保安全） */ -}}
    {{- if $isMap }}
      {{- $nameMap := fromYaml $name }}
      {{- $values := values $nameMap | sortAlpha }}
      {{- if empty $values }}
        {{- fail "empty map provided with no valid name sources" }}
      {{- end }}
      {{- $firstVal := index $values 0 }}
      {{- if not (kindIs "string" $firstVal) }}
        {{- fail (printf "no valid string name found, fallback value is %T (not string)" $firstVal) }}
      {{- end }}
      {{- $name = $firstVal }}
    {{- end }}
  {{- else }}
    {{- include "base.faild" . }}
  {{- end }}

  {{- /* 标准化名称格式：字符串处理 + 小写 + 去空格 + 清除结尾所有横线 */ -}}
  {{- $name = include "base.string" $name | lower | nospace | trimSuffix "-" }}

  {{- /* 验证名称是否符合 RFC1035 标准 */ -}}
  {{- $const := include "base.env" . | fromYaml }}
  {{- if regexMatch $const.regexRFC1035 $name }}
    {{- $name }}
  {{- else }}
    {{- fail (printf "name '%s' does not match RFC1035 standard (regex: %s)" $name $const.regexRFC1035) }}
  {{- end }}
{{- end }}

{{/*
  功能：通过 range 遍历数据源，高效处理各类值（利用 mustMerge 递归合并 map）
  参数：list 格式，依次为：上下文(.)、目标键名
  返回：
    - 基本类型：原始值
    - slice：合并、去重、递归处理嵌套元素后的 YAML
    - map：通过 mustMerge 递归合并后的 YAML
*/}}
{{- define "base.getValWithKey" -}}
  {{- if or (not (kindIs "slice" .)) (ne (len .) 2) }}
    {{- fail "Must be a slice and requires 2 parameters. format: '[.(any), key(string)]'" }}
  {{- end }}

  {{- $root := index . 0 }}
  {{- $key := index . 1 }}

  {{- /* 初始化数据源（确保为dict，避免nil） */ -}}
  {{- $ctx := $root.Context | default dict }}
  {{- $values := $root.Values | default dict }}
  {{- $global := $values.global | default dict }}

  {{- /* 取值 */ -}}
  {{- $ctxVal := get $ctx $key | default "" }}
  {{- $valVal := get $values $key | default "" }}
  {{- $globalVal := get $global $key | default "" }}

  {{- /* 定义数据源 按优先级: .Context > .Values > .Values.global */ -}}
  {{- $sources := list $ctxVal $valVal $globalVal }}

  {{- $result := "" }}
  {{- $slices := list }}
  {{- $maps := list }}
  {{- $basicTypes := list "string" "float64" "int" "int64" "bool" }}

  {{- range $sources }}
    {{- if and . (not $result) }}
      {{- $valType := kindOf . }}
      {{- if has $valType $basicTypes }}
        {{- $result = . }}
      {{- else if kindIs "slice" . }}
        {{- $slices = append $slices . }}
      {{- else if kindIs "map" . }}
        {{- $maps = append $maps . }}
      {{- end }}
    {{- end }}
  {{- end }}

  {{- if $result }}
    {{- $result }}
  {{- else if gt (len $slices) 0 }}
    {{- $merged := list }}
    {{- range $slices }}
      {{- $merged = append $merged . }}
    {{- end }}

    {{- $clean := list }}
    {{- range $merged }}
      {{- if or (kindIs "slice" .) (kindIs "map" .) }}
        {{- $clean = append $clean (include "base.getValWithKey" (list $root $key) | fromYaml) }}
      {{- else }}
        {{- $clean = append $clean . }}
      {{- end }}
    {{- end }}

    {{- toYaml (uniq (mustCompact $clean)) }}
  {{- else if gt (len $maps) 0 }}
    {{- $clean := dict }}
    {{- range $maps }}
      {{- $clean = mustMerge $clean . }}
    {{- end }}

    {{- toYaml $clean }}
  {{- end }}
{{- end }}
