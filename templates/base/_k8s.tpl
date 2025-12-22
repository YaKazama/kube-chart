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
  labels 统一处理: labels(object)、helmLabels(bool)、justNameLabel(bool)

  justNameLabel 与 labels 和 helmLabels 互斥
*/ -}}
{{- define "base.labels" -}}
  {{- $isHelmLabels := include "base.getValue" (list . "helmLabels") }}
  {{- $isJustNameLabel := include "base.getValue" (list . "justNameLabel") }}

  {{- $labels := dict }}
  {{- if $isJustNameLabel }}
    {{- $name := include "base.name" . }}
    {{- $labels = dict "name" $name }}

  {{- else }}
    {{- $_labels := include "base.getValue" (list . "labels") | fromYaml }}
    {{- $labels = mustMerge $labels $_labels }}
    {{- if $isHelmLabels }}
      {{- $helmLabels := include "base.helmLabels" . | fromYaml }}
      {{- $labels = mustMerge $labels $helmLabels }}
    {{- end }}
  {{- end }}

  {{- if $labels }}
    {{- toYamlPretty $labels }}
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

  {{- if mustRegexMatch $const.k8s.quantity (toString .) }}
    {{- . }}
  {{- else }}
    {{- include "base.faild" (dict "iName" "base.Quantity" "iValue" .) }}
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

    {{- if regexMatch $const.types.int . }}
      {{- duration (atoi .) }}
    {{- else if regexMatch $const.k8s.time . }}
      {{- . }}
    {{- else }}
      {{- include "base.faild" (dict "iName" "base.Time" "iValue" . "iLine" 1) }}
    {{- end }}
  {{- else }}
    {{- include "base.faild" (dict "iName" "base.Time" "iValue" . "iLine" 2) }}
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

  {{- if mustRegexMatch $const.k8s.fieldsV1 . }}
    {{- . }}
  {{- else }}
    {{- include "base.faild" (dict "iName" "base.FieldsV1" "iValue" .) }}
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

    {{- if mustRegexMatch $const.types.percent . }}
      {{- . }}
    {{- else }}
      {{- include "base.faild" (dict "iName" "base.RollingUpdate" "iValue" . "iLine" 1) }}
    {{- end }}
  {{- else }}
    {{- include "base.faild" (dict "iName" "base.RollingUpdate" "iValue" . "iLine" 2) }}
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
    {{- fail (printf "base.name: Type not support! Values: %s, type: %s (%s)" . (typeOf .) (kindOf .)) }}
  {{- end }}

  {{- /* 正则校验 */ -}}
  {{- $const := include "base.env" "" | fromYaml }}
  {{- if not (regexMatch $const.rfc.RFC1035 $name) }}
    {{- fail (printf "base.name: '%s' invalid (must match RFC1035: %s)" $name $const.rfc.RFC1035) }}
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
  {{- if not (regexMatch $const.rfc.RFC1123 $namespace) }}
    {{- fail (printf "base.namespace: '%s'(%s) invalid (must match RFC1123: %s)" $namespace (kindOf $namespace) $const.rfc.RFC1123) }}
  {{- end }}

  {{- $namespace }}
{{- end }}


{{- define "base.name.rbac" -}}
  {{- $name := "" }}
  {{- if kindIs "map" . }}
    {{- $fullnameVal := include "base.getValue" (list . "fullname") }}
    {{- $nameVal := include "base.getValue" (list . "name") }}
    {{- $name = coalesce $fullnameVal $nameVal (printf "helm4-name-%s" (randAlpha 8)) | lower | nospace | trimSuffix "-" }}
  {{- else if kindIs "string" . }}
    {{- $name = . }}
  {{- else }}
    {{- fail (printf "base.name.rbac: Type not support! Values: %s, type: %s (%s)" . (typeOf .) (kindOf .)) }}
  {{- end }}

  {{- /* 正则校验 */ -}}
  {{- $const := include "base.env" "" | fromYaml }}
  {{- if not (regexMatch $const.rfc.RFC1035RBAC $name) }}
    {{- fail (printf "base.name.rbac: '%s' invalid (must match RFC1035RBAC: %s)" $name $const.rfc.RFC1035RBAC) }}
  {{- end }}

  {{- $name }}
{{- end }}


{{- define "base.name.apiservice" -}}
  {{- $name := "" }}
  {{- if kindIs "map" . }}
    {{- $fullnameVal := include "base.getValue" (list . "fullname") }}
    {{- $nameVal := include "base.getValue" (list . "name") }}
    {{- $name = coalesce $fullnameVal $nameVal (printf "helm4-name-%s" (randAlpha 8)) | lower | nospace | trimSuffix "-" }}
  {{- else if kindIs "string" . }}
    {{- $name = . }}
  {{- else }}
    {{- fail (printf "base.name.apiservice: Type not support! Values: %s, type: %s (%s)" . (typeOf .) (kindOf .)) }}
  {{- end }}

  {{- /* 正则校验 */ -}}
  {{- $const := include "base.env" "" | fromYaml }}
  {{- if not (regexMatch $const.rfc.APIService $name) }}
    {{- fail (printf "base.name.apiservice: '%s' invalid (must match APIService: %s)" $name $const.rfc.APIService) }}
  {{- end }}

  {{- $name }}
{{- end }}


{{- define "base.rfc1035" -}}
  {{- $const := include "base.env" "" | fromYaml }}
  {{- if not (regexMatch $const.rfc.RFC1035 .) }}
    {{- fail (printf "base.rfc1035: '%s'(%s) invalid (must match RFC1035: %s)" . (kindOf .) $const.rfc.RFC1035) }}
  {{- end }}

  {{- . }}
{{- end }}


{{- define "base.rfc1123" -}}
  {{- $const := include "base.env" "" | fromYaml }}
  {{- if not (regexMatch $const.rfc.RFC1123 .) }}
    {{- fail (printf "base.rfc1123 '%s'(%s) invalid (must match RFC1123: %s)" . (kindOf .) $const.rfc.RFC1123) }}
  {{- end }}

  {{- . }}
{{- end }}


{{- define "base.rfc1035.rbac" -}}
  {{- $const := include "base.env" "" | fromYaml }}
  {{- if not (regexMatch $const.rfc.RFC1035RBAC .) }}
    {{- fail (printf "base.rfc1035.rbac '%s'(%s) invalid (must match RFC1035RBAC: %s)" . (kindOf .) $const.rfc.RFC1035RBAC) }}
  {{- end }}

  {{- . }}
{{- end }}
