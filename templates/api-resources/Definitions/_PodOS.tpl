{{- define "definitions.PodOS" -}}
  {{- /* name string */ -}}
  {{- $name := include "base.getValue" (list . "name") }}
  {{- $nameAllows := list "linux" "windows" }}
  {{- if $name }}
    {{- include "base.field" (list "name" $name "base.string" $nameAllows) }}
  {{- end }}
{{- end }}
