{{- define "definitions.ContainerResizePolicy" -}}
  {{- $regex := "^(cpu|memory)\\s*(NotRequired|RestartContainer)?$" }}

  {{- $match := regexFindAll $regex . -1 }}
  {{- if not $match }}
    {{- fail (printf "volumeDevice: error. Values: %s, format: 'resourceName [restartPolicy]'" .) }}
  {{- end }}

  {{- /* resourceName string */ -}}
  {{- $resourceName := regexReplaceAll $regex . "${1}" }}
  {{- include "base.field" (list "resourceName" $resourceName) }}

  {{- /* resourcePolicy string */ -}}
  {{- $resourcePolicy := regexReplaceAll $regex . "${2}" }}
  {{- if $resourcePolicy }}
    {{- include "base.field" (list "resourcePolicy" $resourcePolicy) }}
  {{- end }}
{{- end }}
