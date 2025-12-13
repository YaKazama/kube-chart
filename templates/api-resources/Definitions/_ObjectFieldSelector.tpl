{{- define "definitions.ObjectFieldSelector" -}}
  {{- $const := include "base.env" "" | fromYaml }}

  {{- $match := regexFindAll $const.regexObjectFieldSelector . -1 }}
  {{- if not $match }}
    {{- fail (printf "ObjectFieldSelector: error, Values: %s, format: 'fieldPath [apiVersion]'" .) }}
  {{- end }}

  {{- /* apiVersion string */ -}}
  {{- $apiVersion := regexReplaceAll $const.regexObjectFieldSelector . "${2}" }}
  {{- if $apiVersion }}
    {{- include "base.field" (list "apiVersion" $apiVersion) }}
  {{- end }}

  {{- /* fieldPath string */ -}}
  {{- $fieldPath := regexReplaceAll $const.regexObjectFieldSelector . "${1}" }}
  {{- include "base.field" (list "fieldPath" $fieldPath) }}
{{- end }}
