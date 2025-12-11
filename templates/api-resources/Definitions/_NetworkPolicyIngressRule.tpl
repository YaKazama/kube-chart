{{- define "definitions.NetworkPolicyIngressRule" -}}
  {{- /* from arry */ -}}
  {{- $fromVal := include "base.getValue" (list . "from") | fromYamlArray }}
  {{- $from := list }}
  {{- range $fromVal }}
    {{- $from = append $from (include "definitions.NetworkPolicyPeer" . | fromYaml) }}
  {{- end }}
  {{- $from = $from | mustUniq | mustCompact }}
  {{- if $from }}
    {{- include "base.field" (list "from" $from "base.slice") }}
  {{- end }}

  {{- /* ports arry */ -}}
  {{- $portsVal := include "base.getValue" (list . "ports") | fromYamlArray }}
  {{- $ports := list }}
  {{- range $portsVal }}
    {{- $ports = append $ports (include "definitions.NetworkPolicyPort" . | fromYaml) }}
  {{- end }}
  {{- $ports = $ports | mustUniq | mustCompact }}
  {{- if $ports }}
    {{- include "base.field" (list "ports" $ports "base.slice") }}
  {{- end }}
{{- end }}
