{{- define "workloads.Deployment" -}}
  {{- $_ := set . "_pkind" "" }}
  {{- $_ := set . "_kind" "Deployment" }}

  {{- include "base.field" (list "apiVersion" "apps/v1") }}
  {{- include "base.field" (list "kind" "Deployment") }}

  {{- /* metadata ObjectMeta */ -}}
  {{- $metadata := include "definitions.ObjectMeta" . | fromYaml }}
  {{- if $metadata }}
    {{- include "base.field" (list "metadata" $metadata "base.map") }}
  {{- end }}

  {{- /* spec DeploymentSpec */ -}}
  {{- $spec := include "workloads.DeploymentSpec" . | fromYaml }}
  {{- if $spec }}
    {{- include "base.field" (list "spec" $spec "base.map") }}
  {{- end }}
{{- end }}
