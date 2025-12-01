{{- define "definitions.StatefulSetPersistentVolumeClaimRetentionPolicy" -}}
  {{- $regex := "^(Retain|retain|Delete|delete)?(?:\\s+(Retain|retain|Delete|delete))?$" }}

  {{- $match := regexFindAll $regex . -1 }}
  {{- if not $match }}
    {{- fail (printf "StatefulSetPersistentVolumeClaimRetentionPolicy: error. Values: %s, format: '[whenDeleted] [whenScaled]'" .) }}
  {{- end }}

  {{- /* whenDeleted string */ -}}
  {{- $whenDeleted := regexReplaceAll $regex . "${1}" | title }}
  {{- if $whenDeleted }}
    {{- include "base.field" (list "whenDeleted" $whenDeleted) }}
  {{- end }}

  {{- /* whenScaled string */ -}}
  {{- $whenScaled := regexReplaceAll $regex . "${2}" | title }}
  {{- if $whenScaled }}
    {{- include "base.field" (list "whenScaled" $whenScaled) }}
  {{- end }}
{{- end }}
