{{- define "service.ServiceSpec" -}}
  {{- /* allocateLoadBalancerNodePorts bool */ -}}
  {{- $allocateLoadBalancerNodePorts := include "base.getValue" (list . "allocateLoadBalancerNodePorts") }}
  {{- if $allocateLoadBalancerNodePorts }}
    {{- include "base.field" (list "allocateLoadBalancerNodePorts" $allocateLoadBalancerNodePorts "base.bool") }}
  {{- end }}

  {{- /* clusterIP string */ -}}
  {{- $clusterIP := include "base.getValue" (list . "clusterIP") }}
  {{- if $clusterIP }}
    {{- include "base.field" (list "clusterIP" $clusterIP "base.ip") }}
  {{- end }}

  {{- /* clusterIPs string array */ -}}
  {{- $clusterIPs := include "base.getValue" (list . "clusterIPs") | fromYamlArray }}
  {{- if $clusterIPs }}
    {{- include "base.field" (list "clusterIPs" $clusterIPs "base.slice.ips") }}
  {{- end }}

  {{- /* externalIPs string array */ -}}
  {{- $externalIPs := include "base.getValue" (list . "externalIPs") | fromYamlArray }}
  {{- if $externalIPs }}
    {{- include "base.field" (list "externalIPs" $externalIPs "base.slice.ips") }}
  {{- end }}

  {{- /* externalName string */ -}}
  {{- $externalIPs := include "base.getValue" (list . "externalIPs") }}
  {{- if $externalIPs }}
    {{- include "base.field" (list "externalIPs" $externalIPs "base.slice") }}
  {{- end }}

  {{- /* externalTrafficPolicy string */ -}}
  {{- $externalIPs := include "base.getValue" (list . "externalIPs") }}
  {{- if $externalIPs }}
    {{- include "base.field" (list "externalIPs" $externalIPs) }}
  {{- end }}

  {{- /* healthCheckNodePort int */ -}}
  {{- $externalIPs := include "base.getValue" (list . "externalIPs") }}
  {{- if $externalIPs }}
    {{- include "base.field" (list "externalIPs" $externalIPs) }}
  {{- end }}

  {{- /* internalTrafficPolicy string */ -}}
  {{- $internalTrafficPolicy := include "base.getValue" (list . "internalTrafficPolicy") }}
  {{- $internalTrafficPolicyAllows := list "Cluster" "Local" }}
  {{- if $internalTrafficPolicy }}
    {{- include "base.field" (list "internalTrafficPolicy" $internalTrafficPolicy "base.string" $internalTrafficPolicyAllows) }}
  {{- end }}

  {{- /* ipFamilies string array */ -}}
  {{- $ipFamilies := include "base.getValue" (list . "ipFamilies") | fromYamlArray }}
  {{- if $ipFamilies }}
    {{- include "base.field" (list "ipFamilies" $ipFamilies "base.slice") }}
  {{- end }}

  {{- /* ipFamilyPolicy string */ -}}
  {{- $ipFamilyPolicy := include "base.getValue" (list . "ipFamilyPolicy") }}
  {{- $ipFamilyPolicyAllows := list "SingleStack" "PreferDualStack" "RequireDualStack" }}
  {{- if $ipFamilyPolicy }}
    {{- include "base.field" (list "ipFamilyPolicy" $ipFamilyPolicy "base.string" $ipFamilyPolicyAllows) }}
  {{- end }}

  {{- /* loadBalancerClass string */ -}}
  {{- $_type := include "base.getValue" (list . "type") }}
  {{- if eq $_type "LoadBalancer" }}
    {{- $loadBalancerClass := include "base.getValue" (list . "loadBalancerClass") }}
    {{- if $loadBalancerClass }}
      {{- include "base.field" (list "loadBalancerClass" $loadBalancerClass) }}
    {{- end }}
  {{- end }}

  {{- /* loadBalancerIP string */ -}}
  {{- $loadBalancerIP := include "base.getValue" (list . "loadBalancerIP") }}
  {{- if $loadBalancerIP }}
    {{- include "base.field" (list "loadBalancerIP" $loadBalancerIP "base.ip") }}
  {{- end }}

  {{- /* loadBalancerSourceRanges string array */ -}}
  {{- $loadBalancerSourceRanges := include "base.getValue" (list . "loadBalancerSourceRanges") | fromYamlArray }}
  {{- if $loadBalancerSourceRanges }}
    {{- include "base.field" (list "loadBalancerSourceRanges" $loadBalancerSourceRanges "base.slice.ips") }}
  {{- end }}

  {{- /* ports array */ -}}
  {{- $const := include "base.env" "" | fromYaml }}
  {{- $portsVal := include "base.getValue" (list . "ports") | fromYamlArray }}
  {{- $ports := list }}
  {{- range $portsVal }}
    {{- $_ports := toString . }}
    {{- $match := regexFindAll $const.regexServiceSpecPorts $_ports -1 }}
    {{- if not $match }}
      {{- fail (printf "ServiceSpec: ports error. Values: %s, format: '[nodePort:]port[:targetPort][/protocol][@appProtocol][#name]'" $_ports) }}
    {{- end }}

    {{- $val := dict }}
    {{- $_ := set $val "nodePort" (regexReplaceAll $const.regexServiceSpecPorts $_ports "${1}") }}
    {{- $_ := set $val "port" (regexReplaceAll $const.regexServiceSpecPorts $_ports "${2}") }}
    {{- $_ := set $val "targetPort" (regexReplaceAll $const.regexServiceSpecPorts $_ports "${3}") }}
    {{- $_ := set $val "protocol" (regexReplaceAll $const.regexServiceSpecPorts $_ports "${4}") }}
    {{- $_ := set $val "appProtocol" (regexReplaceAll $const.regexServiceSpecPorts $_ports "${5}") }}
    {{- $_ := set $val "name" (regexReplaceAll $const.regexServiceSpecPorts $_ports "${6}") }}

    {{- $ports = append $ports (include "definitions.ServicePort" $val | fromYaml) }}
  {{- end }}
  {{- $ports = $ports | mustUniq | mustCompact }}
  {{- if $ports }}
    {{- include "base.field" (list "ports" $ports "base.slice") }}
  {{- end }}

  {{- /* publishNotReadyAddresses bool */ -}}
  {{- $publishNotReadyAddresses := include "base.getValue" (list . "publishNotReadyAddresses") }}
  {{- if $publishNotReadyAddresses }}
    {{- include "base.field" (list "publishNotReadyAddresses" $publishNotReadyAddresses "base.bool") }}
  {{- end }}

  {{- /* selector object/map */ -}}
  {{- $_type := include "base.getValue" (list . "type") }}
  {{- $_selectorAllows := list "ClusterIP" "NodePort" "LoadBalancer" }}
  {{- if mustHas $_type $_selectorAllows }}
    {{- $selectorVal := include "base.getValue" (list . "selector") | fromYaml }}
    {{- $selector := dict }}
    {{- /* 将 labels helmLabels 追加到 selector 中 */ -}}
    {{- $selector = mustMerge $selector (include "base.getValue" (list . "labels") | fromYaml) }}
    {{- $isHelmLabels := include "base.getValue" (list . "helmLabels") }}
    {{- if $isHelmLabels }}
      {{- $selector = mustMerge $selector (include "base.helmLabels" . | fromYaml) }}
    {{- end }}
    {{- if $selector }}
      {{- include "base.field" (list "selector" $selector "base.map") }}
    {{- end }}
  {{- end }}

  {{- /* sessionAffinity string */ -}}
  {{- $sessionAffinity := include "base.getValue" (list . "sessionAffinity") }}
  {{- $sessionAffinityAllows := list "ClientIP" "None" }}
  {{- if $sessionAffinity }}
    {{- include "base.field" (list "sessionAffinity" $sessionAffinity "base.string" $sessionAffinityAllows) }}
  {{- end }}

  {{- /* sessionAffinityConfig map */ -}}
  {{- $sessionAffinityConfigVal := include "base.getValue" (list . "sessionAffinityConfig") | int }}
  {{- if $sessionAffinityConfigVal }}
    {{- $_sessionAffinityConfigVal := dict }}
    {{- $_ := set $_sessionAffinityConfigVal "timeoutSeconds" $sessionAffinityConfigVal }}
    {{- $_ := set $_sessionAffinityConfigVal "sessionAffinity" $sessionAffinity }}
    {{- $sessionAffinityConfig := include "definitions.SessionAffinityConfig" $_sessionAffinityConfigVal | fromYaml }}
    {{- if $sessionAffinityConfig }}
      {{- include "base.field" (list "sessionAffinityConfig" $sessionAffinityConfig "base.map") }}
    {{- end }}
  {{- end }}

  {{- /* trafficDistribution string */ -}}
  {{- $trafficDistribution := include "base.getValue" (list . "trafficDistribution") }}
  {{- $trafficDistributionAllows := list "PreferClose" "PreferSameZone" "PreferSameNode" }}
  {{- if $trafficDistribution }}
    {{- include "base.field" (list "trafficDistribution" $trafficDistribution "base.string" $trafficDistributionAllows) }}
  {{- end }}

  {{- /* type string */ -}}
  {{- $type := include "base.getValue" (list . "type") }}
  {{- $typeAllows := list "ExternalName" "ClusterIP" "NodePort" "LoadBalancer" }}
  {{- if $type }}
    {{- include "base.field" (list "type" $type "base.string" $typeAllows) }}
  {{- end }}
{{- end }}
