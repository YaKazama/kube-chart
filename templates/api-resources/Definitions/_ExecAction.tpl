{{- define "definitions.ExecAction" -}}
  {{- /* command string array */ -}}
  {{- $command := include "base.getValue" (list . "command") | fromYamlArray }}
  {{- if $command }}
    {{- include "base.field" (list "command" $command "base.slice") }}
  {{- end }}
{{- end }}
