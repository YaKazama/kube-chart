{{- define "definitions.VolumeMount" -}}
  {{- $regex := "^(\\S+)\\s+(\\S+)\\s*(\\S+)?\\s*(\\S+)?\\s*(true|false)?\\s*(Disabled|IfPossible|Enabled)?\\s*(Bidirectional|HostToContainer|None)?$" }}

  {{- $match := regexFindAll $regex . -1 }}
  {{- if not $match }}
    {{- fail (printf "configMap: error. Values: %s, format: 'name mountPath [subPath] [subPathExpr] [readOnly] [recursiveReadOnly] [mountPropagation]'" .) }}
  {{- end }}

  {{- /* mountPath string */ -}}
  {{- $mountPath := regexReplaceAll $regex . "${2}" }}
  {{- include "base.field" (list "mountPath" $mountPath) }}

  {{- /* name string */ -}}
  {{- $name := regexReplaceAll $regex . "${1}" }}
  {{- include "base.field" (list "name" $name) }}

  {{- /* readOnly bool */ -}}
  {{- $readOnly := regexReplaceAll $regex . "${5}" }}
  {{- if $readOnly }}
    {{- include "base.field" (list "readOnly" $readOnly "base.bool") }}
  {{- end }}

  {{- /* recursiveReadOnly string */ -}}
  {{- /* mountPropagation string */ -}}
  {{- $recursiveReadOnly := regexReplaceAll $regex . "${6}" }}
  {{- $mountPropagation := regexReplaceAll $regex . "${7}" }}
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
  {{- $subPath := regexReplaceAll $regex . "${3}" }}
  {{- $subPathExpr := regexReplaceAll $regex . "${4}" }}
  {{- if $subPath }}
    {{- include "base.field" (list "subPath" $subPath) }}
  {{- else }}
    {{- include "base.field" (list "subPathExpr" $subPathExpr) }}
  {{- end }}

{{- end }}
