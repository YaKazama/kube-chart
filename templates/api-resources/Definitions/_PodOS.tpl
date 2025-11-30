{{- define "definitions.PodOS" -}}
  {{- /* name */ -}}
  {{- $osAllows := list "linux" "windows" }}
  {{- include "base.field" (list "name" . "base.string" $osAllows) }}
{{- end }}
