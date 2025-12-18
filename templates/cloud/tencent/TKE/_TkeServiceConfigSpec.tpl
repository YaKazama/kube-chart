{{- define "tke.TkeServiceConfigSpec" -}}
  {{- /* loadBalancer map */ -}}
  {{- $loadBalancerVal := include "base.getValue" (list . "loadBalancer") | fromYaml }}
  {{- if $loadBalancerVal }}
    {{- $loadBalancer := include "serviceConfig.LoadBalancer" $loadBalancerVal | fromYaml }}
    {{- if $loadBalancer }}
      {{- include "base.field" (list "loadBalancer" $loadBalancer "base.map") }}
    {{- end }}
  {{- end }}
{{- end }}
