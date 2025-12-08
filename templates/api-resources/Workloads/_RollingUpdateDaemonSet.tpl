{{- define "workloads.RollingUpdateDaemonSet" -}}
  {{- /* maxSurge */ -}}
  {{- $maxSurge := include "base.getValue" (list . "maxSurge") }}
  {{- if $maxSurge }}
    {{- include "base.field" (list "maxSurge" $maxSurge) }}
  {{- end }}

  {{- /* maxUnavailable */ -}}
  {{- $maxUnavailable := include "base.getValue" (list . "maxUnavailable") }}
  {{- if $maxUnavailable }}
    {{- include "base.field" (list "maxUnavailable" $maxUnavailable) }}
  {{- end }}
{{- end }}
