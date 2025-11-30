{{- define "definitions.SleepAction" -}}
  {{- /* seconds int */ -}}
  {{- include "base.field" (list "seconds" . "base.int") }}
{{- end }}
