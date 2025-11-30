{{- /*
  处理方式，同 definitions.LabelSelectorRequirement 但多 Gt Lt
*/ -}}
{{- define "definitions.NodeSelectorRequirement" -}}
  {{- $regexEquality := "^[A-Za-z0-9-]+\\s+(([=]{1,2}|!=)\\s+[A-Za-z0-9-]+|[><]\\s+\\+?\\d+)$" }}
  {{- $regexSet := "^[A-Za-z0-9-]+\\s+(([iI][nN]|[nN][oO][tT][iI][nN])\\s+\\(([A-Za-z0-9-]+(\\s+|\\s*,\\s*)*)+\\)|([gG][tT]|[lL][tT])\\s+\\d+)$" }}
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
      {{- else if eq (index $split 1) ">" }}
        {{- $operator = "Gt" }}
      {{- else if eq (index $split 1) "<" }}
        {{- $operator = "Lt" }}
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
      {{- else if eq (index $split 1 | lower) "gt" }}
        {{- $operator = "Gt" }}
      {{- else if eq (index $split 1 | lower) "lt" }}
        {{- $operator = "Lt" }}
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
    {{- else if or (eq (get $val "operator") "Gt") (eq (get $val "operator") "Lt") }}
      {{- /* 取 values 中的第一个元素，用 base.int 格式化，然后再将值重新赋给 values */ -}}
      {{- $_values := include "base.int" (first (get $val "values")) }}
      {{- $_ := set $val "values" (list $_values) }}
    {{- end }}
    {{- $_labelSelectorRequirement = $val }}
  {{- end }}

  {{- if $_labelSelectorRequirement }}
    {{- toYamlPretty $_labelSelectorRequirement }}
  {{- end }}
{{- end }}
