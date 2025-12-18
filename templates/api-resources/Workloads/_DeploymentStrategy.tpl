{{- define "workloads.DeploymentStrategy" -}}
  {{- /* type string */ -}}
  {{- $type := include "base.getValue" (list . "type") }}
  {{- $typeAllows := list "Recreate" "RollingUpdate" }}
  {{- if $type }}
    {{- include "base.field" (list "type" $type "base.string" $typeAllows) }}
  {{- end }}

  {{- /* rollingUpdate map */ -}}
  {{- if or (eq $type "RollingUpdate") (empty $type) }}
    {{- $rollingUpdateVal := include "base.getValue" (list . "rollingUpdate") | fromYaml }}
    {{- if $rollingUpdateVal }}
      {{- $rollingUpdate := include "workloads.RollingUpdateDeployment" $rollingUpdateVal | fromYaml }}
      {{- if $rollingUpdate }}
        {{- include "base.field" (list "rollingUpdate" $rollingUpdate "base.map") }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}
