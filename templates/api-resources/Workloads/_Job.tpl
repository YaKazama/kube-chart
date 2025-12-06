{{- define "workloads.Job" -}}
  {{- $_ := set . "_pkind" "" }}
  {{- $_ := set . "_kind" "Job" }}

  {{- include "base.field" (list "apiVersion" "batch/v1") }}
  {{- include "base.field" (list "kind" "Job") }}

  {{- /* metadata ObjectMeta */ -}}
  {{- $metadata := include "definitions.ObjectMeta" . | fromYaml }}
  {{- if $metadata }}
    {{- include "base.field" (list "metadata" $metadata "base.map") }}
  {{- end }}

  {{- /* spec JobSpec */ -}}
  {{- $spec := include "workloads.JobSpec" . | fromYaml }}
  {{- if $spec }}
    {{- include "base.field" (list "spec" $spec "base.map") }}
  {{- end }}
{{- end }}
