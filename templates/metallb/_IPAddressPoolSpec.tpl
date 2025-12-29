{{- define "metallb.IPAddressPoolSpec" -}}
  {{- /* addresses string array */ -}}
  {{- $addresses := include "base.getValue" (list . "addresses") | fromYamlArray }}
  {{- if $addresses }}
    {{- include "base.field" (list "addresses" $addresses "base.slice.ips") }}
  {{- end }}
{{- end }}
