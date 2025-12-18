{{- define "definitions.StatefulSetOrdinals" -}}
  {{- /* start int */ -}}
  {{- $start := include "base.getValue" (list . "start") }}
  {{- if $start }}
    {{- include "base.field" (list "start" $start "base.int") }}
  {{- end }}
{{- end }}
