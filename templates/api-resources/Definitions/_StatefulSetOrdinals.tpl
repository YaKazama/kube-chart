{{- define "definitions.StatefulSetOrdinals" -}}
  {{- /* start int */ -}}
  {{- include "base.field" (list "start" . "base.int") }}
{{- end }}
