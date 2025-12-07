{{- define "definitions.SessionAffinityConfig" -}}
  {{- /* clientIP map */ -}}
  {{- $clientIP := include "definitions.ClientIPConfig" . | fromYaml }}
  {{- if $clientIP }}
    {{- include "base.field" (list "clientIP" $clientIP "base.map") }}
  {{- end }}
{{- end }}
