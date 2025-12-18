{{- define "gke.ManagedCertificateSpec" -}}
  {{- /* domains array */ -}}
  {{- $domains := include "base.getValue" (list . "domains") | fromYamlArray }}
  {{- if $domains }}
    {{- include "base.field" (list "domains" $domains "base.slice") }}
  {{- end }}
{{- end }}
