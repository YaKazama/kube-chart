{{- define "definitions.EmptyDirVolumeSource" -}}
  {{- /* medium string */ -}}
  {{- $medium := include "base.getValue" (list . "medium") }}
  {{- if $medium }}
    {{- include "base.field" (list "medium" $medium) }}
  {{- end }}

  {{- /* sizeLimit Quantity */ -}}
  {{- $sizeLimit := include "base.getValue" (list . "sizeLimit") }}
  {{- if $sizeLimit }}
    {{- include "base.field" (list "sizeLimit" $sizeLimit "base.Quantity") }}
  {{- end }}
{{- end }}
