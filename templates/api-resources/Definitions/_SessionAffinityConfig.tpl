{{- define "definitions.SessionAffinityConfig" -}}
  {{- /* clientIP map */ -}}
  {{- $clientIPVal := include "base.getValue" (list . "clientIP") | fromYaml }}
  {{- if $clientIPVal }}
    {{- $val := pick $clientIPVal "timeoutSeconds" "sessionAffinity" }}
    {{- $clientIP := include "definitions.ClientIPConfig" $val | fromYaml }}
    {{- if $clientIP }}
      {{- include "base.field" (list "clientIP" $clientIP "base.map") }}
    {{- end }}
  {{- end }}
{{- end }}
