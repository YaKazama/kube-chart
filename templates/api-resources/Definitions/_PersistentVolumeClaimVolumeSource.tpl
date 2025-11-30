{{- define "definitions.PersistentVolumeClaimVolumeSource" -}}
  {{- $regex := "^(\\S+)\\s*(true|false)?$" }}

  {{- $match := regexFindAll $regex . -1 }}
  {{- if not $match }}
    {{- fail (printf "pvc: error. Values: %s, format: 'claimName [readOnly]'" .) }}
  {{- end }}

  {{- /* claimName string */ -}}
  {{- $claimName := regexReplaceAll $regex . "${1}" | trim }}
  {{- include "base.field" (list "claimName" $claimName) }}

  {{- /* readOnly bool */ -}}
  {{- $readOnly := regexReplaceAll $regex . "${2}" | trim }}
  {{- if $readOnly }}
    {{- include "base.field" (list "readOnly" $readOnly "base.bool") }}
  {{- end }}
{{- end }}
