{{- /*
  从 .Chart 中获取 Name 和 Version 组成完整的 chart 名称或以 "chart-" 为前缀的随机名称
*/ -}}
{{- define "base.chart" -}}
  {{- if and .Chart .Chart.Name .Chart.Version }}
    {{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
  {{- else }}
    {{- printf "chart-%s" (randAlpha 8 | lower) }}
  {{- end }}
{{- end }}

{{- /*
  helm labels
  more: https://helm.sh/docs/chart_best_practices/labels/#standard-labels
*/ -}}
{{- define "base.helmLabels" -}}
  {{- nindent 0 "" -}}helm.sh/chart: {{ include "base.chart" . }}
  {{- if and .Chart .Chart.AppVersion }}
    {{- nindent 0 "" -}}app.kubernetes.io/version: {{ .Chart.AppVersion }}
  {{- else }}
    {{- nindent 0 "" -}}app.kubernetes.io/version: {{ printf "ver-%s" (randNumeric 8) }}
  {{- end }}
  {{- if and .Release .Release.Service }}
    {{- nindent 0 "" -}}app.kubernetes.io/managed-by: {{ .Release.Service }}
  {{- else }}
    {{- nindent 0 "" -}}app.kubernetes.io/managed-by: Helm4
  {{- end }}
{{- end }}

{{- /*
  使用正则表达式检查 Quantity 是否合法
  参考：https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.34/#quantity-resource-core

  return: string / number
*/ -}}
{{- define "base.Quantity" -}}
  {{- include "base.invalid" . }}

  {{- $const := include "base.env" "" | fromYaml }}

  {{- if mustRegexMatch $const.regexQuantity (toString .) }}
    {{- . }}
  {{- else }}
    {{- include "base.faild" (dict "iName" "base.Quantity" "iValue" . "iLine" 44) }}
  {{- end }}
{{- end }}

{{- /*
  使用正则表达式检查 Time 是否合法
  参考：https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.34/#time-v1-meta

  return: string
*/ -}}
{{- define "base.Time" -}}
  {{- include "base.invalid" . }}

  {{- $typesNum := list "float64" "int" "int64" }}
  {{- $typesStr := list "string" }}

  {{- $type := kindOf . }}

  {{- if mustHas $type $typesNum }}
    {{- duration (int .) }}
  {{- else if mustHas $type $typesStr }}
    {{- $const := include "base.env" "" | fromYaml }}

    {{- if regexMatch $const.regexCheckInt . }}
      {{- duration (atoi .) }}
    {{- else if regexMatch $const.regexTime . }}
      {{- . }}
    {{- else }}
      {{- include "base.faild" (dict "iName" "base.Time" "iValue" . "iLine" 72) }}
    {{- end }}
  {{- else }}
    {{- include "base.faild" (dict "iName" "base.Time" "iValue" . "iLine" 75) }}
  {{- end }}
{{- end }}

{{- /*
  使用正则表达式检查 FieldsV1 是否合法
  参考：https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.34/#fieldsv1-v1-meta

  return: string
*/ -}}
{{- define "base.FieldsV1" -}}
  {{- include "base.invalid" . }}
  {{- include "base.string" . }}

  {{- $const := include "base.env" "" | fromYaml }}

  {{- if mustRegexMatch $const.regexFieldsV1 . }}
    {{- . }}
  {{- else }}
    {{- include "base.faild" (dict "iName" "base.FieldsV1" "iValue" . "iLine" 94) }}
  {{- end }}
{{- end }}

{{- /*
  检查 RollingUpdate 中的值是否合法

  return: int / percent
*/ -}}
{{- define "base.RollingUpdate" -}}
  {{- include "base.invalid" . }}

  {{- $typesNum := list "float64" "int" "int64" }}
  {{- $typesStr := list "string" }}

  {{- $type := kindOf . }}

  {{- if mustHas $type $typesNum }}
    {{- int . }}
  {{- else if mustHas $type $typesStr }}
    {{- $const := include "base.env" "" | fromYaml }}

    {{- if mustRegexMatch $const.regexPercent . }}
      {{- . }}
    {{- else }}
      {{- include "base.faild" (dict "iName" "base.RollingUpdate" "iValue" . "iLine" 119) }}
    {{- end }}
  {{- else }}
    {{- include "base.faild" (dict "iName" "base.RollingUpdate" "iValue" . "iLine" 122) }}
  {{- end }}
{{- end }}


{{- /*
  取 fullnane 和 name 的值
  优先级: fullname > name > name-<8 位随机字符> ( .Context > .Values > .Values.global > 上下文自身 )
  参数: 上下文

  注：如果传入的是一个字符串，也可以用来单纯只做 RFC1035 校验

  return: string
*/ -}}
{{- define "base.name" -}}
  {{- $name := "" }}
  {{- if kindIs "map" . }}
    {{- $fullnameVal := include "base.getValue" (list . "fullname") }}
    {{- $nameVal := include "base.getValue" (list . "name") }}
    {{- $name = coalesce $fullnameVal $nameVal (printf "helm4-name-%s" (randAlpha 8)) | lower | nospace | trimSuffix "-" }}
  {{- else if kindIs "string" . }}
    {{- $name = . }}
  {{- else }}
    {{- fail (printf "Type not support! Values: %s, type: %s (%s)" . (typeOf .) (kindOf .)) }}
  {{- end }}

  {{- /* 正则校验 */ -}}
  {{- $const := include "base.env" "" | fromYaml }}
  {{- if not (regexMatch $const.regexRFC1035 $name) }}
    {{- fail (printf "name '%s' invalid (must match RFC1035: %s)" $name $const.regexRFC1035) }}
  {{- end }}

  {{- $name }}
{{- end }}

{{- /*
  取 namespace 的值
  优先级: .Context > .Values > .Values.global > 上下文自身 > "default"
  参数: 上下文

  return: string
*/ -}}
{{- define "base.namespace" -}}
  {{- $namespace := "default" }}
  {{- if kindIs "string" . }}
    {{- $namespace = . }}
  {{- else if kindIs "map" . }}
    {{- $namespaceVal := include "base.getValue" (list . "namespace") }}
    {{- $namespace = coalesce $namespaceVal "default" | lower | nospace | trimSuffix "-" }}
  {{- end }}

  {{- /*  */ -}}
  {{- $const := include "base.env" "" | fromYaml }}
  {{- if not (regexMatch $const.regexRFC1123 $namespace) }}
    {{- fail (printf "namespace '%s'(%s) invalid (must match RFC1123: %s)" $namespace (kindOf $namespace) $const.regexRFC1123) }}
  {{- end }}

  {{- $namespace }}
{{- end }}
