{{- define "definitions.VolumeMount" -}}
  {{- /* mountPath string */ -}}
  {{- $mountPath := include "base.getValue" (list . "mountPath") }}
  {{- if $mountPath }}
    {{- include "base.field" (list "mountPath" $mountPath "base.absPath") }}
  {{- end }}

  {{- /* name string */ -}}
  {{- $name := include "base.getValue" (list . "name") }}
  {{- if $name }}
    {{- include "base.field" (list "name" $name "base.rfc1035") }}
  {{- end }}

  {{- /* readOnly bool */ -}}
  {{- $readOnly := include "base.getValue" (list . "readOnly") }}
  {{- if $readOnly }}
    {{- include "base.field" (list "readOnly" $readOnly "base.bool") }}
  {{- end }}

  {{- /* recursiveReadOnly string */ -}}
  {{- /* mountPropagation string */ -}}
  {{- $recursiveReadOnly := include "base.getValue" (list . "recursiveReadOnly") }}
  {{- $mountPropagation := include "base.getValue" (list . "mountPropagation") }}
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
  {{- $subPath := include "base.getValue" (list . "subPath") }}
  {{- $subPathExpr := include "base.getValue" (list . "subPathExpr") }}
  {{- if $subPath }}
    {{- include "base.field" (list "subPath" $subPath "base.relPath") }}
  {{- else }}
    {{- include "base.field" (list "subPathExpr" $subPathExpr) }}
  {{- end }}

{{- end }}
