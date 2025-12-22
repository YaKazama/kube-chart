{{- define "gke.BackendConfig" -}}
  {{- $_ := set . "_kind" "BackendConfig" }}

  {{- include "base.field" (list "apiVersion" "cloud.google.com/v1") }}
  {{- include "base.field" (list "kind" "BackendConfig") }}

  {{- /* metadata map */ -}}
  {{- $metadata := include "definitions.ObjectMeta" . | fromYaml }}
  {{- if $metadata }}
    {{- include "base.field" (list "metadata" $metadata "base.map") }}
  {{- end }}

  {{- /* spec map */ -}}
  {{- $spec := include "gke.BackendConfigSpec" . | fromYaml }}
  {{- if $spec }}
    {{- include "base.field" (list "spec" $spec "base.map") }}
  {{- end }}
{{- end }}
