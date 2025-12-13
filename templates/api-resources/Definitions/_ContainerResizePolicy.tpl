{{- define "definitions.ContainerResizePolicy" -}}
  {{- $const := include "base.env" "" | fromYaml }}

  {{- $match := regexFindAll $const.regexContainerResizePolicy . -1 }}
  {{- if not $match }}
    {{- fail (printf "definitions.ContainerResizePolicy: error. Values: %s, format: 'resourceName [restartPolicy]'" .) }}
  {{- end }}

  {{- /* resourceName string */ -}}
  {{- $resourceName := regexReplaceAll $const.regexContainerResizePolicy . "${1}" }}
  {{- include "base.field" (list "resourceName" $resourceName) }}

  {{- /* resourcePolicy string */ -}}
  {{- $resourcePolicy := regexReplaceAll $const.regexContainerResizePolicy . "${2}" }}
  {{- if $resourcePolicy }}
    {{- include "base.field" (list "resourcePolicy" $resourcePolicy) }}
  {{- end }}
{{- end }}
