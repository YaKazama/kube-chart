{{- define "definitions.NetworkPolicyEgressRule" -}}
  {{- /* ports array */ -}}
  {{- $portsVal := include "base.getValue" (list . "ports") | fromYamlArray }}
  {{- $ports := list }}
  {{- range $portsVal }}
    {{- $ports = append $ports (include "definitions.NetworkPolicyPort" . | fromYaml) }}
  {{- end }}
  {{- $ports = $ports | mustUniq | mustCompact }}
  {{- if $ports }}
    {{- include "base.field" (list "ports" $ports "base.slice") }}
  {{- end }}

  {{- /* to array */ -}}
  {{- $toVal := include "base.getValue" (list . "to") | fromYamlArray }}
  {{- $to := list }}
  {{- range $toVal }}
    {{- $to = append $to (include "definitions.NetworkPolicyPort" . | fromYaml) }}
  {{- end }}
  {{- $to = $to | mustUniq | mustCompact }}
  {{- if $to }}
    {{- include "base.field" (list "to" $to "base.slice") }}
  {{- end }}
{{- end }}
