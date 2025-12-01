{{- define "workloads.DaemonSet" -}}
  {{- $_ := set . "_pkind" "" }}
  {{- $_ := set . "_kind" "DaemonSet" }}

  {{- include "base.field" (list "apiVersion" "apps/v1") }}
  {{- include "base.field" (list "kind" "DaemonSet") }}

  {{- /* metadata ObjectMeta */ -}}
  {{- $metadata := include "definitions.ObjectMeta" . | fromYaml }}
  {{- if $metadata }}
    {{- include "base.field" (list "metadata" $metadata "base.map") }}
  {{- end }}

  {{- /* spec DaemonSetSpec */ -}}
  {{- $spec := include "workloads.DaemonSetSpec" . | fromYaml }}
  {{- if $spec }}
    {{- include "base.field" (list "spec" $spec "base.map") }}
  {{- end }}
{{- end }}
