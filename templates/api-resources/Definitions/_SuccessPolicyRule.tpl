{{- define "definitions.SuccessPolicyRule" -}}
  {{- /* succeededCount int */ -}}
  {{- $succeededCount := include "base.getValue" (list . "succeededCount") }}
  {{- if $succeededCount }}
    {{- include "base.field" (list "succeededCount" $succeededCount "base.int") }}
  {{- end }}

  {{- /* succeededIndexes string */ -}}
  {{- $succeededIndexes := include "base.getValue" (list . "succeededIndexes") | nospace }}
  {{- if $succeededIndexes }}
    {{- include "base.field" (list "succeededIndexes" $succeededIndexes) }}
  {{- end }}
{{- end }}
