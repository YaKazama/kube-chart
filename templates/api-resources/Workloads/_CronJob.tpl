{{- define "workloads.CronJob" -}}
  {{- $_ := set . "_pkind" "" }}
  {{- $_ := set . "_kind" "CronJob" }}

  {{- include "base.field" (list "apiVersion" "batch/v1") }}
  {{- include "base.field" (list "kind" "CronJob") }}

  {{- /* metadata ObjectMeta */ -}}
  {{- $metadata := include "definitions.ObjectMeta" . | fromYaml }}
  {{- if $metadata }}
    {{- include "base.field" (list "metadata" $metadata "base.map") }}
  {{- end }}

  {{- /* spec CronJobSpec */ -}}
  {{- $spec := include "workloads.CronJobSpec" . | fromYaml }}
  {{- if $spec }}
    {{- include "base.field" (list "spec" $spec "base.map") }}
  {{- end }}
{{- end }}
