{{- define "definitions.LabelSelector" -}}
  {{- $const := include "base.env" "" | fromYaml }}

  {{- /* matchExpressions array */ -}}
  {{- $matchExpressionsVal := include "base.getValue" (list . "matchExpressions") | fromYamlArray }}
  {{- $matchExpressions := list }}
  {{- range $matchExpressionsVal }}
    {{- $val := dict }}
    {{- $key := "" }}
    {{- $operator := "" }}
    {{- $values := list }}

    {{- if kindIs "string" . }}
      {{- /* 基于等值 */ -}}
      {{- $match0 := regexFindAll $const.k8s.selector.equality0 . -1 }}
      {{- /* 基于集合 */ -}}
      {{- $match1 := regexFindAll $const.k8s.selector.set0 . -1 }}
      {{- $match2 := regexFindAll $const.k8s.selector.setExists . -1 }}

      {{- if $match0 }}
        {{- $key = regexReplaceAll $const.k8s.selector.equality0 . "${1}" }}

        {{- $_operator := regexReplaceAll $const.k8s.selector.equality0 . "${2}" }}
        {{- if or (eq $_operator "=") (eq $_operator "==") }}
          {{- $operator = "In" }}
        {{- else if (eq $_operator "!=") }}
          {{- $operator = "NotIn" }}
        {{- end }}

        {{- $_values := regexReplaceAll $const.k8s.selector.equality0 . "${3}" }}
        {{- $values = include "base.slice.cleanup" (dict "s" $_values) | fromYamlArray }}

        {{- $val = dict "key" $key "operator" $operator "values" $values }}

      {{- else if $match1 }}
        {{- $key = regexReplaceAll $const.k8s.selector.set0 . "${1}" }}

        {{- $_operator := regexReplaceAll $const.k8s.selector.set0 . "${2}" | lower }}
        {{- if eq $_operator "in" }}
          {{- $operator = "In" }}
        {{- else if eq $_operator "notint" }}
          {{- $operator = "NotIn" }}
        {{- end }}

        {{- $_values := regexReplaceAll $const.k8s.selector.set0 . "${3}" }}
        {{- $values = include "base.slice.cleanup" (dict "s" $_values "r" $const.split.comma) | fromYamlArray }}

        {{- $val = dict "key" $key "operator" $operator "values" $values }}

      {{- else if $match2 }}
        {{- $key = trimPrefix "!" . }}

        {{- if hasPrefix "!" . }}
          {{- $operator = "DoesNotExist" }}
        {{- else }}
          {{- $operator = "Exists" }}
        {{- end }}

        {{- $val = dict "key" $key "operator" $operator }}
      {{- end }}

    {{- else if kindIs "map" . }}
      {{- $val = pick . "key" "operator" "values" }}

    {{- else }}
      {{- fail (printf "definitions.LabelSelector: matchExpressions invalid. Values: '%s', Type: '%s, %s'" . (typeOf .) (kindOf .)) }}
    {{- end }}

    {{- $matchExpressions = append $matchExpressions (include "definitions.LabelSelectorRequirement" $val | fromYaml) }}
  {{- end }}
  {{- $matchExpressions = $matchExpressions | mustUniq | mustCompact }}
  {{- if $matchExpressions }}
    {{- include "base.field" (list "matchExpressions" $matchExpressions "base.slice") }}
  {{- end }}

  {{- /* matchLabels object/map */ -}}
  {{- $matchLabels := include "base.getValue" (list . "matchLabels") | fromYaml }}
  {{- if $matchLabels }}
    {{- include "base.field" (list "matchLabels" $matchLabels "base.map") }}
  {{- end }}
{{- end }}
