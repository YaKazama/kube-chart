{{- define "serviceConfig.DomainRule" -}}
  {{- /* url string */ -}}
  {{- $url := include "base.getValue" (list . "url") }}
  {{- if $url }}
    {{- include "base.field" (list "url" $url "base.absPath") }}
  {{- end }}

  {{- /* forwardType string */ -}}
  {{- $forwardType := include "base.getValue" (list . "forwardType") }}
  {{- $forwardTypeAllows := list "HTTP" "HTTPS" "GRPC" }}
  {{- if $forwardType }}
    {{- include "base.field" (list "forwardType" ($forwardType | upper) "base.string" $forwardTypeAllows) }}
  {{- end }}

  {{- /* session map */ -}}
  {{- $sessionVal := include "base.getValue" (list . "session") | fromYaml }}
  {{- if $sessionVal }}
    {{- $session := include "serviceConfig.Session" $sessionVal | fromYaml }}
    {{- if $session }}
      {{- include "base.field" (list "session" $session "base.map") }}
    {{- end }}
  {{- end }}

  {{- /* healthCheck map */ -}}
  {{- $healthCheckVal := include "base.getValue" (list . "healthCheck") | fromYaml }}
  {{- if $healthCheckVal }}
    {{- $healthCheck := include "serviceConfig.HealthCheck" $healthCheckVal | fromYaml }}
    {{- if $healthCheck }}
      {{- include "base.field" (list "healthCheck" $healthCheck "base.map") }}
    {{- end }}
  {{- end }}

  {{- /* scheduler string */ -}}
  {{- $scheduler := include "base.getValue" (list . "scheduler") }}
  {{- $schedulerAllows := list "WRR" "LEAST_CONN" "IP_HASH" }}
  {{- if $scheduler }}
    {{- include "base.field" (list "scheduler" ($scheduler | upper) "base.string" $schedulerAllows) }}
  {{- end }}
{{- end }}
