{{- define "gcp.backend.ConnectionDraining" -}}
  {{- /* drainingTimeoutSec int */ -}}
  {{- $drainingTimeoutSec := include "base.getValue" (list . "drainingTimeoutSec") }}
  {{- if $drainingTimeoutSec }}
    {{- include "base.field" (list "drainingTimeoutSec" (list (int $drainingTimeoutSec) 0 3600) "base.int.range") }}
  {{- end }}
{{- end }}
