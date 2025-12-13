{{- define "definitions.StatefulSetPersistentVolumeClaimRetentionPolicy" -}}
  {{- $const := include "base.env" "" | fromYaml }}

  {{- $match := regexFindAll $const.regexStatefulSetPersistentVolumeClaimRetentionPolicy . -1 }}
  {{- if not $match }}
    {{- fail (printf "StatefulSetPersistentVolumeClaimRetentionPolicy: error. Values: %s, format: '[whenDeleted] [whenScaled]'" .) }}
  {{- end }}

  {{- /* whenDeleted string */ -}}
  {{- $whenDeleted := regexReplaceAll $const.regexStatefulSetPersistentVolumeClaimRetentionPolicy . "${1}" | title }}
  {{- if $whenDeleted }}
    {{- include "base.field" (list "whenDeleted" $whenDeleted) }}
  {{- end }}

  {{- /* whenScaled string */ -}}
  {{- $whenScaled := regexReplaceAll $const.regexStatefulSetPersistentVolumeClaimRetentionPolicy . "${2}" | title }}
  {{- if $whenScaled }}
    {{- include "base.field" (list "whenScaled" $whenScaled) }}
  {{- end }}
{{- end }}
