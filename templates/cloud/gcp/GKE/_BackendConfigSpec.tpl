{{- define "gke.BackendConfigSpec" -}}
  {{- /* timeoutSec int */ -}}
  {{- $timeoutSec := include "base.getValue" (list . "timeoutSec") }}
  {{- if $timeoutSec }}
    {{- include "base.field" (list "timeoutSec" $timeoutSec "base.int") }}
  {{- end }}

  {{- /* connectionDraining map */ -}}
  {{- $connectionDrainingVal := include "base.getValue" (list . "connectionDraining") | fromYaml }}
  {{- if $connectionDrainingVal }}
    {{- $connectionDraining := include "gcp.backend.ConnectionDraining" $connectionDrainingVal | fromYaml }}
    {{- if $connectionDraining }}
      {{- include "base.field" (list "connectionDraining" $connectionDraining "base.map") }}
    {{- end }}
  {{- end }}

  {{- /* healthCheck map */ -}}
  {{- $healthCheckVal := include "base.getValue" (list . "healthCheck") | fromYaml }}
  {{- if $healthCheckVal }}
    {{- $healthCheck := include "gcp.backend.HealthCheck" $healthCheckVal | fromYaml }}
    {{- if $healthCheck }}
      {{- include "base.field" (list "healthCheck" $healthCheck "base.map") }}
    {{- end }}
  {{- end }}

  {{- /* logging map */ -}}
  {{- $loggingVal := include "base.getValue" (list . "logging") | fromYaml }}
  {{- if $loggingVal }}
    {{- $logging := include "gcp.backend.Logging" $loggingVal | fromYaml }}
    {{- if $logging }}
      {{- include "base.field" (list "logging" $logging "base.map") }}
    {{- end }}
  {{- end }}
{{- end }}
