{{- /*
  使用正则表达式检查 Quantity 是否合法
  参考：https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.34/#quantity-resource-core

  return: string / number
*/ -}}
{{- define "base.Quantity" -}}
  {{- include "base.invalid" . }}

  {{- $const := include "base.env" . | fromYaml }}

  {{- if mustRegexMatch $const.regexQuantity (toString .) }}
    {{- . }}
  {{- else }}
    {{- include "base.fail" . }}
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
    {{- $const := include "base.env" . | fromYaml }}

    {{- if regexMatch $const.regexCheckInt . }}
      {{- duration (atoi .) }}
    {{- else if regexMatch $const.regexTime . }}
      {{- . }}
    {{- else }}
      {{- include "base.fail" . }}
    {{- end }}
  {{- else }}
    {{- include "base.faild" . }}
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

  {{- $const := include "base.env" . | fromYaml }}

  {{- if mustRegexMatch $const.regexFieldsV1 . }}
    {{- . }}
  {{- else }}
    {{- include "base.faild" . }}
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
    {{- $const := include "base.env" . | fromYaml }}

    {{- if mustRegexMatch $const.regexRollingUpdate . }}
      {{- . }}
    {{- else }}
      {{- include "base.faild" . }}
    {{- end }}
  {{- else }}
    {{- include "base.faild" . }}
  {{- end }}
{{- end }}
