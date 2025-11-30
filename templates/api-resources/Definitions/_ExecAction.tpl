{{- define "definitions.ExecAction" -}}
  {{- /* command string array */ -}}
  {{- include "base.field" (list "command" . "base.slice") }}
{{- end }}
