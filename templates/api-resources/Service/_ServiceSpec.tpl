{{- define "service.ServiceSpec" -}}
  {{- $const := include "base.env" "" | fromYaml }}

  {{- /* allocateLoadBalancerNodePorts bool */ -}}
  {{- $allocateLoadBalancerNodePorts := include "base.getValue" (list . "allocateLoadBalancerNodePorts" "toString") }}
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
  {{- $externalName := include "base.getValue" (list . "externalName") }}
  {{- if $externalName }}
    {{- include "base.field" (list "externalName" $externalName "base.rfc1123") }}
  {{- end }}

  {{- /* externalTrafficPolicy string */ -}}
  {{- $externalTrafficPolicy := include "base.getValue" (list . "externalTrafficPolicy") }}
  {{- $externalTrafficPolicyAllows := list "Cluster" "Local" }}
  {{- if $externalTrafficPolicy }}
    {{- include "base.field" (list "externalTrafficPolicy" $externalTrafficPolicy "base.string" $externalTrafficPolicyAllows) }}
  {{- end }}

  {{- /* healthCheckNodePort int */ -}}
  {{- $healthCheckNodePort := include "base.getValue" (list . "healthCheckNodePort") }}
  {{- $_externalTrafficPolicy := include "base.getValue" (list . "externalTrafficPolicy") }}
  {{- $_type := include "base.getValue" (list . "type") }}
  {{- if and $healthCheckNodePort (eq $_type "LoadBalancer") (eq $_externalTrafficPolicy "Local") }}
    {{- include "base.field" (list "healthCheckNodePort" $healthCheckNodePort "base.int") }}
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
    {{- include "base.field" (list "ipFamilies" (dict "s" $ipFamilies "c" $const.k8s.service.ipFamilies) "base.slice.cleanup") }}
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
  {{- /* Deprecated: This field was under-specified and its meaning varies across implementations. Using it is non-portable and it may not support dual-stack. Users are encouraged to use implementation-specific annotations when available. */ -}}
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
  {{- $portsVal := include "base.getValue" (list . "ports") | fromYamlArray }}
  {{- $ports := list }}
  {{- range $portsVal }}
    {{- $_ports := toString . }}
    {{- $match := regexFindAll $const.k8s.service.ports $_ports -1 }}
    {{- if not $match }}
      {{- fail (printf "ServiceSpec: ports error. Values: %s, format: '[nodePort:]port[:targetPort][/protocol][@appProtocol][#name]'" $_ports) }}
    {{- end }}

    {{- $nodePort := regexReplaceAll $const.k8s.service.ports $_ports "${1}" | trim }}
    {{- $port := regexReplaceAll $const.k8s.service.ports $_ports "${2}" | trim }}
    {{- $targetPort := regexReplaceAll $const.k8s.service.ports $_ports "${3}" | trim }}
    {{- $protocol := regexReplaceAll $const.k8s.service.ports $_ports "${4}" | trim }}
    {{- $appProtocol := regexReplaceAll $const.k8s.service.ports $_ports "${5}" | trim }}
    {{- $name := regexReplaceAll $const.k8s.service.ports $_ports "${6}" | trim }}
    {{- $val := dict "nodePort" $nodePort "port" $port "targetPort" $targetPort "protocol" $protocol "appProtocol" $appProtocol "name" $name }}

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
    {{- $selector := include "base.getValue" (list . "selector") | fromYaml }}
    {{- $labels := include "base.getValue" . | fromYaml }}
    {{- $selector = merge $selector $labels }}
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
    {{- $val := dict "clientIP" (dict "timeoutSeconds" $sessionAffinityConfigVal "sessionAffinity" $sessionAffinity) }}
    {{- $sessionAffinityConfig := include "definitions.SessionAffinityConfig" $val | fromYaml }}
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
