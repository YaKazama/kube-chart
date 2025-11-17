{{- define "base.chart" -}}
  {{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "base.helmLabels" -}}
  {{- nindent 0 "" -}}helm.sh/chart: {{ include "base.chart" . }}
  {{- nindent 0 "" -}}app.kubernetes.io/version: {{ .Chart.AppVersion }}
  {{- nindent 0 "" -}}app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "base.name" -}}
  {{- $__name := "" }}

  {{- if kindIs "string" . }}
    {{- $__name = . }}
  {{- else if kindIs "map" . }}
    {{- /* 优先从 Context 获取名称 */}}
    {{- if .Context }}
      {{- $ctxName := coalesce .Context.fullname .Context.name }}
      {{- if $ctxName }}
        {{- $__clean := include "base.name" $ctxName }}
        {{- $__name = coalesce $__name $__clean }}
      {{- end }}
    {{- end }}

    {{- /* 从 Values 获取名称（次于 Context） */}}
    {{- if .Values }}
      {{- $valName := coalesce .Values.fullname .Values.name }}
      {{- if $valName }}
        {{- $__clean := include "base.name" $valName }}
        {{- $__name = coalesce $__name $__clean }}
      {{- end }}

      {{- /* 从全局 Values 获取名称（次于 Values） */}}
      {{- if .Values.global }}
        {{- $gloName := coalesce .Values.global.fullname .Values.global.name }}
        {{- if $gloName }}
          {{- $__clean := include "base.name" $gloName }}
          {{- $__name = coalesce $__name $__clean }}
        {{- end }}
      {{- end }}
    {{- end }}

    {{- /* 从 Chart 名称 fallback（次于 Values.global） */}}
    {{- if not $__name }}
      {{- $__name = .Chart.Name | default "" }}
    {{- end }}

    {{- /* 最终 fallback：从 map 值中取第一个字符串（确保安全） */}}
    {{- if empty $__name }}
      {{- $values := values . | sortAlpha }}
      {{- if empty $values }}
        {{- include "base.faild" "empty map provided with no valid name sources" }}
      {{- end }}
      {{- $firstVal := index $values 0 }}
      {{- if not (kindIs "string" $firstVal) }}
        {{- include "base.faild" (printf "no valid string name found, fallback value is %T (not string)" $firstVal) }}
      {{- end }}
      {{- $__name = $firstVal }}
    {{- end }}
  {{- else }}
    {{- include "base.faild" . }}
  {{- end }}

  {{- /* 标准化名称格式：字符串处理 + 小写 + 去空格 + 清除结尾所有横线 */}}
  {{- $__name = include "base.string" $__name | lower | nospace | trimSuffix "-" }}

  {{- /* 验证名称是否符合 RFC1035 标准 */}}
  {{- $__const := include "base.env" . | fromYaml }}
  {{- if regexMatch $__const.regexRFC1035 $__name }}
    {{- $__name }}
  {{- else }}
    {{- include "base.faild" . }}
  {{- end }}
{{- end }}
