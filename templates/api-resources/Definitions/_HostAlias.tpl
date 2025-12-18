{{- define "definitions.HostAlias" -}}
  {{- /* hostnames */ -}}
  {{- $hostnames := include "base.getValue" (list . "hostnames") | fromYamlArray }}
  {{- if $hostnames }}
    {{- include "base.field" (list "hostnames" $hostnames "base.slice") }}
  {{- end }}

  {{- /* ip */ -}}
  {{- $ip := include "base.getValue" (list . "ip") }}
  {{- if $ip }}
    {{- include "base.field" (list "ip" $ip "base.ip") }}
  {{- end }}
{{- end }}
