{{- define "metallb.L2AdvertisementSpec" -}}
  {{- /* ipAddressPools string array */ -}}
  {{- $ipAddressPools := include "base.getValue" (list . "ipAddressPools") | fromYamlArray }}
  {{- if $ipAddressPools }}
    {{- include "base.field" (list "ipAddressPools" $ipAddressPools "base.slice") }}
  {{- end }}
{{- end }}
