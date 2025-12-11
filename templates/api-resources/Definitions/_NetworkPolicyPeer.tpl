{{- define "definitions.NetworkPolicyPeer" -}}
  {{- /* ipBlock map */ -}}
  {{- $ipBlockVal := include "base.getValue" (list . "ipBlock") | fromYaml }}
  {{- $ipBlock := include "definitions.IPBlock" $ipBlockVal | fromYaml }}
  {{- if $ipBlock }}
    {{- include "base.field" (list "ipBlock" $ipBlock "base.map") }}
  {{- end }}

  {{- /* namespaceSelector map */ -}}
  {{- $namespaceSelectorVal := include "base.getValue" (list . "namespaceSelector") | fromYaml }}
  {{- $namespaceSelector := include "definitions.LabelSelector" $namespaceSelectorVal | fromYaml }}
  {{- if $namespaceSelector }}
    {{- include "base.field" (list "namespaceSelector" $namespaceSelector "base.map") }}
  {{- end }}

  {{- /* podSelector map */ -}}
  {{- $podSelectorVal := include "base.getValue" (list . "podSelector") | fromYaml }}
  {{- $podSelector := include "definitions.LabelSelector" $podSelectorVal | fromYaml }}
  {{- if $podSelector }}
    {{- include "base.field" (list "podSelector" $podSelector "base.map") }}
  {{- end }}
{{- end }}
