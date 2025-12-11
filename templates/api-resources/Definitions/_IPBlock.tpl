{{- define "definitions.IPBlock" -}}
  {{- /* cidr string */ -}}
  {{- $cidr := include "base.getValue" (list . "cidr") }}
  {{- if $cidr }}
    {{- include "base.field" (list "cidr" $cidr "base.ip") }}
  {{- end }}

  {{- /* execpt string array */ -}}
  {{- $execpt := include "base.getValue" (list . "except") | fromYamlArray }}
  {{- if $execpt }}
    {{- include "base.field" (list "execpt" $execpt "base.slice.ips") }}
  {{- end }}
{{- end }}
