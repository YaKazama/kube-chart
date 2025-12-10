{{- define "definitions.ImageVolumeSource" -}}
  {{- /* pullPolicy string */ -}}
  {{- $pullPolicy := include "base.getValue" (list . "pullPolicy") }}
  {{- if $pullPolicy }}
    {{- include "base.field" (list "pullPolicy" $pullPolicy) }}
  {{- end }}

  {{- /* reference string */ -}}
  {{- $reference := include "base.getValue" (list . "reference") }}
  {{- if $reference }}
    {{- include "base.field" (list "reference" $reference) }}
  {{- end }}
{{- end }}
