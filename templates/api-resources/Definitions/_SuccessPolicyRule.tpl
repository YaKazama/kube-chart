{{- define "definitions.SuccessPolicyRule" -}}
  {{- if kindIs "float64" . }}  {{- /* 若只有一个数字，则作为 succeededCount */ -}}
    {{- /* succeededCount int */ -}}
    {{- $succeededCount := . }}
    {{- if $succeededCount }}
      {{- include "base.field" (list "succeededCount" $succeededCount "base.int") }}
    {{- end }}

  {{- else if kindIs "string" . }}
    {{- $regex := "^(\\d+)?(?:\\s*((?:\\d+(?:-\\d+)?)(?:,\\s*\\d+(?:-\\d+)?)*))?$" }}

    {{- $match := regexFindAll $regex . -1 }}
    {{- if not $match }}
      {{- fail (printf "SuccessPolicyRule: error. Values: %s, format: '[succeededCount] [succeededIndexes]'" .) }}
    {{- end }}

    {{- /* succeededCount int */ -}}
    {{- $succeededCount := regexReplaceAll $regex . "${1}" }}
    {{- if $succeededCount }}
      {{- include "base.field" (list "succeededCount" $succeededCount "base.int") }}
    {{- end }}

    {{- /* succeededIndexes string */ -}}
    {{- $succeededIndexes := regexReplaceAll $regex . "${2}" | nospace }}
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
