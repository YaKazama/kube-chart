{{- define "definitions.ResourceFieldSelector" -}}
  {{- /* containerName string */ -}}
  {{- $containerName := include "base.getValue" (list . "containerName") }}
  {{- if $containerName }}
    {{- include "base.field" (list "containerName" $containerName) }}
  {{- end }}

  {{- /* divisor Quantity */ -}}
  {{- $divisor := include "base.getValue" (list . "divisor") }}
  {{- if and $divisor (gt $divisor "0") }}
    {{- include "base.field" (list "divisor" $divisor "base.Quantity") }}
  {{- end }}

  {{- /* resource string */ -}}
  {{- $resource := include "base.getValue" (list . "resource") }}
  {{- if $resource }}
    {{- include "base.field" (list "resource" $resource) }}
  {{- end }}
{{- end }}
