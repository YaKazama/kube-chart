{{- define "definitions.VolumeMount" -}}
  {{- $const := include "base.env" "" | fromYaml }}

  {{- $match := regexFindAll $const.regexVolumeMount . -1 }}
  {{- if not $match }}
    {{- fail (printf "configMap: error. Values: %s, format: 'name mountPath [subPath] [subPathExpr] [readOnly] [recursiveReadOnly] [mountPropagation]'" .) }}
  {{- end }}

  {{- /* mountPath string */ -}}
  {{- $mountPath := regexReplaceAll $const.regexVolumeMount . "${2}" }}
  {{- include "base.field" (list "mountPath" $mountPath "base.absPath") }}

  {{- /* name string */ -}}
  {{- $name := regexReplaceAll $const.regexVolumeMount . "${1}" }}
  {{- include "base.field" (list "name" $name) }}

  {{- /* readOnly bool */ -}}
  {{- $readOnly := regexReplaceAll $const.regexVolumeMount . "${5}" }}
  {{- if $readOnly }}
    {{- include "base.field" (list "readOnly" $readOnly "base.bool") }}
  {{- end }}

  {{- /* recursiveReadOnly string */ -}}
  {{- /* mountPropagation string */ -}}
  {{- $recursiveReadOnly := regexReplaceAll $const.regexVolumeMount . "${6}" }}
  {{- $mountPropagation := regexReplaceAll $const.regexVolumeMount . "${7}" }}
  {{- if $readOnly }}
    {{- if $recursiveReadOnly }}
      {{- include "base.field" (list "recursiveReadOnly" $recursiveReadOnly) }}
    {{- end }}
  {{- end }}
  {{- if not (or (eq $recursiveReadOnly "IfPossible") (eq $recursiveReadOnly "Enabled")) }}
    {{- if $mountPropagation }}
      {{- include "base.field" (list "mountPropagation" $mountPropagation) }}
    {{- end }}
  {{- end }}

  {{- /* subPath string */ -}}
  {{- /* subPathExpr string */ -}}
  {{- $subPath := regexReplaceAll $const.regexVolumeMount . "${3}" }}
  {{- $subPathExpr := regexReplaceAll $const.regexVolumeMount . "${4}" }}
  {{- if $subPath }}
    {{- include "base.field" (list "subPath" $subPath "base.relPath") }}
  {{- else }}
    {{- include "base.field" (list "subPathExpr" $subPathExpr) }}
  {{- end }}

{{- end }}
