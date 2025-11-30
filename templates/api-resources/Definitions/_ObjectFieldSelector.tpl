{{- define "definitions.ObjectFieldSelector" -}}
  {{- $regex := "^field\\s+(\\S+)(?:\\s+(\\S+))?$" }}

  {{- $match := regexFindAll $regex . -1 }}
  {{- if not $match }}
    {{- fail (printf "ObjectFieldSelector: error, Values: %s, format: 'fieldPath [apiVersion]'" .) }}
  {{- end }}

  {{- /* apiVersion string */ -}}
  {{- $apiVersion := regexReplaceAll $regex . "${2}" }}
  {{- if $apiVersion }}
    {{- include "base.field" (list "apiVersion" $apiVersion) }}
  {{- end }}

  {{- /* fieldPath string */ -}}
  {{- $fieldPath := regexReplaceAll $regex . "${1}" }}
  {{- include "base.field" (list "fieldPath" $fieldPath) }}
{{- end }}
