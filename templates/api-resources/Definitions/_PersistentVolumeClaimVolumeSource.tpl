{{- define "definitions.PersistentVolumeClaimVolumeSource" -}}
  {{- /* claimName string */ -}}
  {{- $claimName := include "base.getValue" (list . "claimName") }}
  {{- include "base.field" (list "claimName" $claimName) }}

  {{- /* readOnly bool */ -}}
  {{- $readOnly := include "base.getValue" (list . "readOnly") }}
  {{- if $readOnly }}
    {{- include "base.field" (list "readOnly" $readOnly "base.bool") }}
  {{- end }}
{{- end }}
