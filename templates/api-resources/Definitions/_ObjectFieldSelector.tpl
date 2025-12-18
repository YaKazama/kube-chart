{{- define "definitions.ObjectFieldSelector" -}}
  {{- /* apiVersion string */ -}}
  {{- $apiVersion := include "base.getValue" (list . "apiVersion") }}
  {{- if $apiVersion }}
    {{- include "base.field" (list "apiVersion" $apiVersion) }}
  {{- end }}

  {{- /* fieldPath string */ -}}
  {{- $fieldPath := include "base.getValue" (list . "fieldPath") }}
  {{- include "base.field" (list "fieldPath" $fieldPath) }}
{{- end }}
