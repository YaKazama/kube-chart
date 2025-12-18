{{- define "definitions.ContainerResizePolicy" -}}
  {{- /* resourceName string */ -}}
  {{- $resourceName := include "base.getValue" (list . "resourceName") }}
  {{- $resourceNameAllows := list "cpu" "memory" }}
  {{- if $resourceName }}
    {{- include "base.field" (list "resourceName" $resourceName "base.string" $resourceNameAllows) }}
  {{- end }}

  {{- /* resourcePolicy string */ -}}
  {{- $resourcePolicy := include "base.getValue" (list . "resourcePolicy") }}
  {{- $resourcePolicyAllows := list "NotRequired" "RestartContainer" }}
  {{- if $resourcePolicy }}
    {{- include "base.field" (list "resourcePolicy" $resourcePolicy "base.string" $resourcePolicyAllows) }}
  {{- end }}
{{- end }}
