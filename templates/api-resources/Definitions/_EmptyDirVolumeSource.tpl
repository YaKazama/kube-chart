{{- define "definitions.EmptyDirVolumeSource" -}}
  {{- $regex := "^(Memory)?\\s*([+-]?(\\d+\\.?\\d{0,3}|\\.\\d{1,3})([KMGTPE]i|[mkMGTPE]|[eE]\\s?[+-]?(\\d+\\.?\\d{0,3}|\\.\\d{1,3}))?)?$" }}

  {{- /*
    {{- $match := regexFindAll $regex . -1 }}
    {{- if not $match }}
      {{- fail (printf "emptyDir: error. Values: %s, format: '[medium] [sizeLimit]'" .) }}
    {{- end }}
  */ -}}

  {{- /* medium string */ -}}
  {{- $medium := regexReplaceAll $regex . "${1}" | trim }}
  {{- if $medium }}
    {{- include "base.field" (list "medium" $medium) }}
  {{- end }}

  {{- /* sizeLimit Quantity */ -}}
  {{- $sizeLimit := regexReplaceAll $regex . "${2}" | trim }}
  {{- if $sizeLimit }}
    {{- include "base.field" (list "sizeLimit" $sizeLimit "base.Quantity") }}
  {{- end }}
{{- end }}
