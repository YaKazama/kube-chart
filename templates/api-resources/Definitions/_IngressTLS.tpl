{{- define "definitions.IngressTLS" -}}
  {{- /* hosts string array */ -}}
  {{- $hosts := include "base.getValue" (list . "hosts") | fromYamlArray }}
  {{- if $hosts }}
    {{- include "base.field" (list "hosts" $hosts "base.slice") }}
  {{- end }}

  {{- /* secretName string */ -}}
  {{- $secretName := include "base.getValue" (list . "secretName") }}
  {{- if $secretName }}
    {{- include "base.field" (list "secretName" $secretName) }}
  {{- end }}
{{- end }}
