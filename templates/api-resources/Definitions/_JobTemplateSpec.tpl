{{- define "definitions.JobTemplateSpec" -}}
  {{- $_ := set . "_pkind" (get . "_kind") }}
  {{- $_ := set . "_kind" "JobTemplateSpec" }}

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
