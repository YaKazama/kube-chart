{{- /*
  渲染 Kubernetes LabelSelectorRequirement。参考 https://kubernetes.io/docs/reference/kubernetes-api/definitions/label-selector-requirement-v1-meta/

  行为:
    - key (string, 必填): 标签选择器的键，独立字段，单字段闭环 (取-校验-渲染)。
    - operator (string, 必填): 仅允许 In、NotIn、Exists、DoesNotExist。
    - values (array, 条件必填): 与 operator 强关联 (In/NotIn 必须非空; Exists/DoesNotExist 必须空)，例外集中处理后按 API 顺序渲染。

  核心字段: dict，包含 key、operator 和可选 values。

  返回值: LabelSelectorRequirement YAML 对象。

  示例:
    {{- include "definitions.labelSelectorRequirement" (dict "key" "environment" "operator" "In" "values" (list "production")) }}
*/ -}}
{{- define "definitions.labelSelectorRequirement" -}}
  {{- /* Step 1: key (string, 必填, 独立字段): 单字段闭环 (取-校验-渲染) */ -}}
  {{- $_key := include "base.get" (list . "key") }}
  {{- if or (not $_key) (eq $_key "null") }}
    {{- fail "[definitions.labelSelectorRequirement] key: required field is missing or empty" }}
  {{- end }}
  {{- if not (kindIs "string" $_key) }}
    {{- fail "[definitions.labelSelectorRequirement] key: must be string type" }}
  {{- end }}
  {{- include "base.field" (list "key" $_key "base.string") }}

  {{- /* Step 2: operator (string, 必填, 与 values 强关联): 集中处理后渲染 */ -}}
  {{- $_operator := include "base.get" (list . "operator") }}
  {{- if or (not $_operator) (eq $_operator "null") }}
    {{- fail "[definitions.labelSelectorRequirement] operator: required field is missing or empty" }}
  {{- end }}
  {{- $operators := list "In" "NotIn" "Exists" "DoesNotExist" }}
  {{- if not (mustHas $_operator $operators) }}
    {{- fail (printf "[definitions.labelSelectorRequirement] operator: must be one of %v, got '%s'" $operators $_operator) }}
  {{- end }}

  {{- /* Step 3: values (array, 条件必填, 与 operator 强关联): 集中处理后按 operator 条件渲染 */ -}}
  {{- $_valuesRaw := include "base.get" (list . "values") }}
  {{- $values := list }}
  {{- $hasValues := and $_valuesRaw (ne $_valuesRaw "null") }}
  {{- if $hasValues }}
    {{- if not (or (hasPrefix "- " $_valuesRaw) (eq $_valuesRaw "[]")) }}
      {{- fail "[definitions.labelSelectorRequirement] values: must be array type" }}
    {{- end }}
    {{- $values = $_valuesRaw | fromYamlArray }}
    {{- if eq (include "base.isFromYamlArrayError" $values) "true" }}
      {{- fail "[definitions.labelSelectorRequirement] values: must be array type" }}
    {{- end }}
    {{- range $value := $values }}
      {{- if not (kindIs "string" $value) }}
        {{- fail "[definitions.labelSelectorRequirement] values: each element must be string type" }}
      {{- end }}
      {{- if not $value }}
        {{- fail "[definitions.labelSelectorRequirement] values: empty element is not allowed" }}
      {{- end }}
    {{- end }}
  {{- end }}

  {{- if or (eq $_operator "In") (eq $_operator "NotIn") }}
    {{- if eq (len $values) 0 }}
      {{- fail (printf "[definitions.labelSelectorRequirement] values: must be a non-empty array when operator is '%s'" $_operator) }}
    {{- end }}

  {{- else if gt (len $values) 0 }}
    {{- fail (printf "[definitions.labelSelectorRequirement] values: must be empty when operator is '%s'" $_operator) }}
  {{- end }}

  {{- include "base.field" (list "operator" $_operator "base.string") }}

  {{- if or (eq $_operator "In") (eq $_operator "NotIn") }}
    {{- include "base.field" (list "values" $values "base.slice") }}
  {{- end }}
{{- end -}}
