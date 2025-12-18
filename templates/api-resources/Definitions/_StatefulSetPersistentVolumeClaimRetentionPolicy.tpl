{{- define "definitions.StatefulSetPersistentVolumeClaimRetentionPolicy" -}}
  {{- /* whenDeleted string */ -}}
  {{- $whenDeleted := include "base.getValue" (list . "whenDeleted") }}
  {{- if $whenDeleted }}
    {{- include "base.field" (list "whenDeleted" $whenDeleted) }}
  {{- end }}

  {{- /* whenScaled string */ -}}
  {{- $whenScaled := include "base.getValue" (list . "whenScaled") }}
  {{- if $whenScaled }}
    {{- include "base.field" (list "whenScaled" $whenScaled) }}
  {{- end }}
{{- end }}
