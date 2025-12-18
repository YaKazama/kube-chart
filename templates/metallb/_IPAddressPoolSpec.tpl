{{- define "metallb.IPAddressPoolSpec" -}}
  {{- /* address string array */ -}}
  {{- $address := include "base.getValue" (list . "address") | fromYamlArray }}
  {{- if $address }}
    {{- include "base.field" (list "address" $address "base.slice.ips") }}
  {{- end }}
{{- end }}
