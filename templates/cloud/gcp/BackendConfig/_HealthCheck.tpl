{{- define "gcp.backend.HealthCheck" -}}
  {{- /* checkIntervalSec int */ -}}
  {{- $checkIntervalSec := include "base.getValue" (list . "checkIntervalSec") }}
  {{- if $checkIntervalSec }}
    {{- include "base.field" (list "checkIntervalSec" $checkIntervalSec "base.int") }}
  {{- end }}

  {{- /* timeoutSec int */ -}}
  {{- $timeoutSec := include "base.getValue" (list . "timeoutSec") }}
  {{- if $timeoutSec }}
    {{- include "base.field" (list "timeoutSec" $timeoutSec "base.int") }}
  {{- end }}

  {{- /* healthyThreshold int */ -}}
  {{- $healthyThreshold := include "base.getValue" (list . "healthyThreshold") }}
  {{- if $healthyThreshold }}
    {{- include "base.field" (list "healthyThreshold" $healthyThreshold "base.int") }}
  {{- end }}

  {{- /* unhealthyThreshold int */ -}}
  {{- $unhealthyThreshold := include "base.getValue" (list . "unhealthyThreshold") }}
  {{- if $unhealthyThreshold }}
    {{- include "base.field" (list "unhealthyThreshold" $unhealthyThreshold "base.int") }}
  {{- end }}

  {{- /* type string */ -}}
  {{- $type := include "base.getValue" (list . "type") }}
  {{- $typeAllows := list "HTTP" "HTTPS" "HTTP2" }}
  {{- if $type }}
    {{- include "base.field" (list "type" $type "base.string" $typeAllows) }}
  {{- end }}

  {{- /* requestPath string */ -}}
  {{- $requestPath := include "base.getValue" (list . "requestPath") }}
  {{- if $requestPath }}
    {{- include "base.field" (list "requestPath" $requestPath "base.absPath") }}
  {{- end }}

  {{- /* port int */ -}}
  {{- $port := include "base.getValue" (list . "port") }}
  {{- if $port }}
    {{- include "base.field" (list "port" $port "base.port") }}
  {{- end }}
{{- end }}
