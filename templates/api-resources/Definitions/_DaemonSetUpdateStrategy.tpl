{{- define "definitions.DaemonSetUpdateStrategy" -}}
  {{- /* rollingUpdate map */ -}}
  {{- $rollingUpdateVal := include "base.getValue" (list . "rollingUpdate") | fromYaml }}
  {{- if $rollingUpdateVal }}
    {{- $rollingUpdate := include "workloads.RollingUpdateDaemonSet" $rollingUpdateVal | fromYaml }}
    {{- if $rollingUpdate }}
      {{- include "base.field" (list "rollingUpdate" $rollingUpdate "base.map") }}
    {{- end }}
  {{- end }}

  {{- /* type string */ -}}
  {{- $type := include "base.getValue" (list . "type") }}
  {{- $typeAllows := list "OnDelete" "RollingUpdate" }}
  {{- if $type }}
    {{- include "base.field" (list "type" $type) }}
  {{- end }}
{{- end }}
