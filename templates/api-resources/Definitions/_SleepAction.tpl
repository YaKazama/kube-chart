{{- define "definitions.SleepAction" -}}
  {{- /* seconds int */ -}}
  {{- $seconds := include "base.getValue" (list . "seconds") }}
  {{- if $seconds }}
    {{- include "base.field" (list "seconds" $seconds "base.int") }}
  {{- end }}
{{- end }}
