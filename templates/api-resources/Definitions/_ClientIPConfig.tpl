{{- define "definitions.ClientIPConfig" -}}
  {{- /* timeoutSeconds int */ -}}
  {{- $sessionAffinity := include "base.getValue" (list . "sessionAffinity") }}
  {{- $timeoutSeconds := include "base.getValue" (list . "timeoutSeconds") }}
  {{- if eq $sessionAffinity "ClientIP" }}
    {{- $timeoutSeconds = include "base.int.range" (list (int $timeoutSeconds) 1 86400) }}
  {{- end }}
  {{- if $timeoutSeconds }}
    {{- include "base.field" (list "timeoutSeconds" $timeoutSeconds "base.int") }}
  {{- end }}
{{- end }}
