{{- define "workloads.StatefulSet" -}}
  {{- $_ := set . "_pkind" "" }}
  {{- $_ := set . "_kind" "StatefulSet" }}

  {{- include "base.field" (list "apiVersion" "apps/v1") }}
  {{- include "base.field" (list "kind" "StatefulSet") }}

  {{- /* metadata ObjectMeta */ -}}
  {{- $metadata := include "definitions.ObjectMeta" . | fromYaml }}
  {{- if $metadata }}
    {{- include "base.field" (list "metadata" $metadata "base.map") }}
  {{- end }}

  {{- /* spec StatefulSetSpec */ -}}
  {{- $spec := include "workloads.StatefulSetSpec" . | fromYaml }}
  {{- if $spec }}
    {{- include "base.field" (list "spec" $spec "base.map") }}
  {{- end }}
{{- end }}
