{{- /*
  参考: https://kubernetes.io/zh-cn/docs/concepts/overview/working-with-objects/labels/#label-selectors

  独立定义格式：
    matchExpressions:
    # 基于等值 / 不等值
    - environment = production
    - environment1 == production1
    - tier != frontend
    # 基于集合
    - environment2 in (production2, qa2)
    - tier2 notin (frontend2, backend2)
    - partition
    - "!partition1"
    # 原生
    - key: key
      operator: In  # In/NotIn
      values:
      - value1
      - value2
    - key: key2
      operator: Exists # Exists/DoesNotExist
*/ -}}
{{- define "definitions.LabelSelectorRequirement" -}}
  {{- $regexEquality := "^[A-Za-z0-9-]+\\s+([=]{1,2}|!=)\\s+[A-Za-z0-9-]+$" }}
  {{- $regexSet := "^[A-Za-z0-9-]+\\s+([iI][nN]|[nN][oO][tT][iI][nN])\\s+\\(([A-Za-z0-9-]+(\\s+|\\s*,\\s*)*)+\\)$" }}
  {{- $regexSetExists := "^!?[A-Za-z0-9-]+" }}
  {{- $const := include "base.env" . | fromYaml }}
  {{- $_labelSelectorRequirement := dict }}

  {{- $key := "" }}
  {{- $operator := "" }}
  {{- $values := list }}

  {{- if kindIs "string" . }}
    {{- if regexMatch $regexEquality . }}
      {{- $split := mustRegexSplit $const.regexSplit . -1 }} {{- /* 使用空格拆分 */ -}}
      {{- $key = index $split 0 }}
      {{- if or (eq (index $split 1) "=") (eq (index $split 1) "==") }}
        {{- $operator = "In" }}
      {{- else if eq (index $split 1) "!=" }}
        {{- $operator = "NotIn" }}
      {{- end }}
      {{- $values = include "base.slice.cleanup" (dict "s" (mustSlice $split 2)) | fromYamlArray }}
      {{- $_labelSelectorRequirement = dict "key" $key "operator" $operator "values" $values }}
    {{- else if regexMatch $regexSet . }}
      {{- $val := mustRegexReplaceAll "(.*)\\((.*),*(.*)*\\)" . "${1} ${2} ${3}" }} {{- /* 移除逗号和括号 */ -}}
      {{- $split := mustRegexSplit $const.regexSplit $val -1 }} {{- /* 使用空格拆分 */ -}}
      {{- $key = index $split 0 }}
      {{- if eq (index $split 1 | lower) "in" }}
        {{- $operator = "In" }}
      {{- else if eq (index $split 1 | lower) "notin" }}
        {{- $operator = "NotIn" }}
      {{- end }}
      {{- $values = include "base.slice.cleanup" (dict "s" (mustSlice $split 2 (len $split))) | fromYamlArray }}
      {{- $_labelSelectorRequirement = dict "key" $key "operator" $operator "values" $values }}
    {{- else if regexMatch $regexSetExists . }}
      {{- $key = trimPrefix "!" . }}
      {{- if hasPrefix "!" . }}
        {{- $operator = "DoesNotExist" }}
      {{- else }}
        {{- $operator = "Exists" }}
      {{- end }}
      {{- $_labelSelectorRequirement = dict "key" $key "operator" $operator }}
    {{- end }}
  {{- else if kindIs "map" . }}
    {{- $val := pick . "key" "operator" "values" }}
    {{- if or (eq (get $val "operator") "Exists") (eq (get $val "operator") "DoesNotExist") }}
      {{- $val = omit $val "values" }}
    {{- end }}
    {{- $_labelSelectorRequirement = $val }}
  {{- end }}

  {{- if $_labelSelectorRequirement }}
    {{- toYamlPretty $_labelSelectorRequirement }}
  {{- end }}
{{- end }}
