{{- define "cluster.NetworkPolicySpec" -}}
  {{- /* egress array */ -}}
  {{- $egressVal := include "base.getValue" (list . "egress") | fromYamlArray }}
  {{- $egress := list }}
  {{- range $egressVal }}
    {{- $egress = append $egress (include "definitions.NetworkPolicyEgressRule" . | fromYaml) }}
  {{- end }}
  {{- $egress = $egress | mustUniq | mustCompact }}
  {{- if $egress }}
    {{- include "base.field" (list "egress" $egress "base.slice") }}
  {{- end }}

  {{- /* ingress array */ -}}
  {{- $ingressVal := include "base.getValue" (list . "ingress") | fromYamlArray }}
  {{- $ingress := list }}
  {{- range $ingressVal }}
    {{- $ingress = append $ingress (include "definitions.NetworkPolicyIngressRule" . | fromYaml) }}
  {{- end }}
  {{- $ingress = $ingress | mustUniq | mustCompact }}
  {{- if $ingress }}
    {{- include "base.field" (list "ingress" $ingress "base.slice") }}
  {{- end }}

  {{- /* podSelector map */ -}}
  {{- $podSelectorVal := include "base.getValue" (list . "podSelector") | fromYaml }}
  {{- if $podSelectorVal }}
    {{- $_ := set $podSelectorVal "_kind" "NetworkPolicySpec" }}
    {{- $podSelector := include "definitions.LabelSelector" $podSelectorVal | fromYaml }}
    {{- if $podSelector }}
      {{- include "base.field" (list "podSelector" $podSelector "base.map") }}
    {{- end }}
  {{- end }}

  {{- /* policyTypes string array */ -}}
  {{- $policyTypes := include "base.getValue" (list . "policyTypes") | fromYamlArray }}
  {{- if $policyTypes }}
    {{- include "base.field" (list "policyTypes" (dict "s" $policyTypes "c" "^(Ingress|Egress)$") "base.slice.cleanup") }}
  {{- end }}
{{- end }}
