{{- define "definitions.ImageVolumeSource" -}}
  {{- $regex := "^(\\S+)\\s*(Always|Never|IfNotPresent)?$" }}

  {{- $match := regexFindAll $regex . -1 }}
  {{- if not $match }}
    {{- fail (printf "image: error. Values: %s, format: 'reference [pullPolicy]'" .) }}
  {{- end }}

  {{- /* pullPolicy string */ -}}
  {{- $pullPolicy := regexReplaceAll $regex . "${2}" }}
  {{- if $pullPolicy }}
    {{- include "base.field" (list "pullPolicy" $pullPolicy) }}
  {{- end }}

  {{- /* reference string */ -}}
  {{- $reference := regexReplaceAll $regex . "${1}" }}
  {{- include "base.field" (list "reference" $reference) }}
{{- end }}
