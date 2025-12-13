{{- define "definitions.SuccessPolicyRule" -}}
  {{- if kindIs "float64" . }}  {{- /* 若只有一个数字，则作为 succeededCount */ -}}
    {{- /* succeededCount int */ -}}
    {{- $succeededCount := . }}
    {{- if $succeededCount }}
      {{- include "base.field" (list "succeededCount" $succeededCount "base.int") }}
    {{- end }}

  {{- else if kindIs "string" . }}
    {{- $const := include "base.env" "" | fromYaml }}

    {{- $match := regexFindAll $const.regexSuccessPolicyRule . -1 }}
    {{- if not $match }}
      {{- fail (printf "SuccessPolicyRule: error. Values: %s, format: '[succeededCount] [succeededIndexes]'" .) }}
    {{- end }}

    {{- /* succeededCount int */ -}}
    {{- $succeededCount := regexReplaceAll $const.regexSuccessPolicyRule . "${1}" }}
    {{- if $succeededCount }}
      {{- include "base.field" (list "succeededCount" $succeededCount "base.int") }}
    {{- end }}

    {{- /* succeededIndexes string */ -}}
    {{- $succeededIndexes := regexReplaceAll $const.regexSuccessPolicyRule . "${2}" | nospace }}
    {{- if $succeededIndexes }}
      {{- include "base.field" (list "succeededIndexes" $succeededIndexes) }}
    {{- end }}

  {{- else if kindIs "map" . }}
    {{- /* succeededCount int */ -}}
    {{- $succeededCount := include "base.getValue" (list . "succeededCount") }}
    {{- if $succeededCount }}
      {{- include "base.field" (list "succeededCount" $succeededCount) }}
    {{- end }}

    {{- /* succeededIndexes string */ -}}
    {{- $succeededIndexes := include "base.getValue" (list . "succeededIndexes") | nospace }}
    {{- if $succeededIndexes }}
      {{- include "base.field" (list "succeededIndexes" $succeededIndexes) }}
    {{- end }}

  {{- end }}
{{- end }}
