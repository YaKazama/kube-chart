{{- define "definitions.NodeSelectorTerm" -}}
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
      {{- $match1 := regexFindAll $const.k8s.selector.equality1 . -1 }}
      {{- /* 基于集合 */ -}}
      {{- $match2 := regexFindAll $const.k8s.selector.set0 . -1 }}
      {{- $match3 := regexFindAll $const.k8s.selector.set1 . -1 }}
      {{- $match4 := regexFindAll $const.k8s.selector.setExists . -1 }}

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
        {{- $key = regexReplaceAll $const.k8s.selector.equality1 . "${1}" }}

        {{- $_operator := regexReplaceAll $const.k8s.selector.equality1 . "${2}" }}
        {{- if eq $_operator ">" }}
          {{- $operator = "Gt" }}
        {{- else if eq $_operator "<" }}
          {{- $operator = "Lt" }}
        {{- end }}

        {{- $_values := regexReplaceAll $const.k8s.selector.equality1 . "${3}" }}
        {{- $values = include "base.slice.cleanup" (dict "s" $_values) | fromYamlArray }}

        {{- $val = dict "key" $key "operator" $operator "values" $values }}

      {{- else if $match2 }}
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

      {{- else if $match3 }}
        {{- $key = regexReplaceAll $const.k8s.selector.set1 . "${1}" }}

        {{- $_operator := regexReplaceAll $const.k8s.selector.set1 . "${2}" | lower }}
        {{- if eq $_operator "gt" }}
          {{- $operator = "Gt" }}
        {{- else if eq $_operator "lt" }}
          {{- $operator = "Lt" }}
        {{- end }}

        {{- $_values := regexReplaceAll $const.k8s.selector.set1 . "${3}" }}
        {{- $values = include "base.slice.cleanup" (dict "s" $_values "r" $const.split.comma) | fromYamlArray }}

        {{- $val = dict "key" $key "operator" $operator "values" $values }}

      {{- else if $match4 }}
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
      {{- fail (printf "definitions.NodeSelectorTerm: matchExpressions invalid. Values: '%s', Type: '%s, %s'" . (typeOf .) (kindOf .)) }}
    {{- end }}

    {{- $matchExpressions = append $matchExpressions (include "definitions.NodeSelectorRequirement" $val | fromYaml) }}
  {{- end }}
  {{- $matchExpressions = $matchExpressions | mustUniq | mustCompact }}
  {{- if $matchExpressions }}
    {{- include "base.field" (list "matchExpressions" $matchExpressions "base.slice") }}
  {{- end }}

  {{- /* matchFields array */ -}}
  {{- $matchFieldsVal := include "base.getValue" (list . "matchFields") | fromYamlArray }}
  {{- $matchFields := list }}
  {{- range $matchFieldsVal }}
    {{- $val := dict }}
    {{- $key := "" }}
    {{- $operator := "" }}
    {{- $values := list }}

    {{- if kindIs "string" . }}
      {{- /* 基于等值 */ -}}
      {{- $match0 := regexFindAll $const.k8s.selector.equality0 . -1 }}
      {{- $match1 := regexFindAll $const.k8s.selector.equality1 . -1 }}
      {{- /* 基于集合 */ -}}
      {{- $match2 := regexFindAll $const.k8s.selector.set0 . -1 }}
      {{- $match3 := regexFindAll $const.k8s.selector.set1 . -1 }}
      {{- $match4 := regexFindAll $const.k8s.selector.setExists . -1 }}

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
        {{- $key = regexReplaceAll $const.k8s.selector.equality1 . "${1}" }}

        {{- $_operator := regexReplaceAll $const.k8s.selector.equality1 . "${2}" }}
        {{- if eq $_operator ">" }}
          {{- $operator = "Gt" }}
        {{- else if eq $_operator "<" }}
          {{- $operator = "Lt" }}
        {{- end }}

        {{- $_values := regexReplaceAll $const.k8s.selector.equality1 . "${3}" }}
        {{- $values = include "base.slice.cleanup" (dict "s" $_values) | fromYamlArray }}

        {{- $val = dict "key" $key "operator" $operator "values" $values }}

      {{- else if $match2 }}
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

      {{- else if $match3 }}
        {{- $key = regexReplaceAll $const.k8s.selector.set1 . "${1}" }}

        {{- $_operator := regexReplaceAll $const.k8s.selector.set1 . "${2}" | lower }}
        {{- if eq $_operator "gt" }}
          {{- $operator = "Gt" }}
        {{- else if eq $_operator "lt" }}
          {{- $operator = "Lt" }}
        {{- end }}

        {{- $_values := regexReplaceAll $const.k8s.selector.set1 . "${3}" }}
        {{- $values = include "base.slice.cleanup" (dict "s" $_values "r" $const.split.comma) | fromYamlArray }}

        {{- $val = dict "key" $key "operator" $operator "values" $values }}

      {{- else if $match4 }}
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
      {{- fail (printf "definitions.NodeSelectorTerm: matchFields invalid. Values: '%s', Type: '%s, %s'" . (typeOf .) (kindOf .)) }}
    {{- end }}

    {{- $matchFields = append $matchFields (include "definitions.NodeSelectorRequirement" $val | fromYaml) }}
  {{- end }}
  {{- $matchFields = $matchFields | mustUniq | mustCompact }}
  {{- if $matchFields }}
    {{- include "base.field" (list "matchFields" $matchFields "base.slice") }}
  {{- end }}
{{- end }}
