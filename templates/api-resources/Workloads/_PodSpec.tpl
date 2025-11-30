{{- define "workloads.PodSpec" -}}
  {{- $_ := set . "_pkind" (get . "_kind") }}
  {{- $_ := set . "_kind" "PodSpec" }}

  {{- $const := include "base.env" . | fromYaml }}

  {{- /* activeDeadlineSeconds int */ -}}
  {{- $activeDeadlineSeconds := include "base.getValue" (list . "activeDeadlineSeconds") }}
  {{- if $activeDeadlineSeconds }}
    {{- include "base.field" (list "activeDeadlineSeconds" $activeDeadlineSeconds "base.int") }}
  {{- end }}

  {{- /* affinity map */ -}}
  {{- /* 由 nodeAffinity podAffinity podAntiAffinity 三个定义完成 */ -}}
  {{- $affinity := include "definitions.Affinity" . | fromYaml }}
  {{- if $affinity }}
    {{- include "base.field" (list "affinity" $affinity "base.map") }}
  {{- end }}

  {{- /* automountServiceAccountToken bool */ -}}
  {{- $automountServiceAccountToken := include "base.getValue" (list . "automountServiceAccountToken") }}
  {{- if $automountServiceAccountToken }}
    {{- include "base.field" (list "automountServiceAccountToken" $automountServiceAccountToken "base.bool") }}
  {{- end }}

  {{- /* containers array */ -}}
  {{- $containersVal := include "base.getValue" (list . "containers") | fromYamlArray }}
  {{- $containers := list }}
  {{- range $containersVal }}
    {{- $osVal := include "base.getValue" (list . "os") }}
    {{- $_ := set . "os" $osVal }}  {{- /* securityContext 需要用到它 */ -}}
    {{- $containers = append $containers (include "workloads.Container" . | fromYaml) }}
  {{- end }}
  {{- $containers = $containers | mustUniq | mustCompact }}
  {{- if $containers }}
    {{- include "base.field" (list "containers" $containers "base.slice") }}
  {{- end }}

  {{- /* dnsPolicy string */ -}}
  {{- $dnsPolicy := include "base.getValue" (list . "dnsPolicy") }}
  {{- $dnsPolicyAllows := list "ClusterFirst" "ClusterFirstWithHostNet" "Default" "None" }}
  {{- if $dnsPolicy }}
    {{- include "base.field" (list "dnsPolicy" $dnsPolicy "base.string" $dnsPolicyAllows) }}
  {{- end }}

  {{- /* hostAliases array */ -}}
  {{- $hostAliasesVal := include "base.getValue" (list . "hostAliases") | fromYamlArray }}
  {{- $hostAliases := list }}
  {{- range $hostAliasesVal }}
    {{- $hostAliases = append $hostAliases (include "definitions.HostAlias" . | fromYaml) }}
  {{- end }}
  {{- $hostAliases = $hostAliases | mustUniq | mustCompact }}
  {{- if $hostAliases }}
    {{- include "base.field" (list "hostAlias" $hostAliases "base.slice") }}
  {{- end }}

  {{- /* hostNetwork bool */ -}}
  {{- $hostnameOverride := include "base.getValue" (list . "hostnameOverride") }}
  {{- if not (regexMatch $const.regexRFC1035 $hostnameOverride) }}
    {{- $hostNetwork := include "base.getValue" (list . "hostNetwork") }}
    {{- if $hostNetwork }}
      {{- include "base.field" (list "hostNetwork" $hostNetwork "base.bool") }}
    {{- end }}
  {{- end }}

  {{- /* hostPID bool 与 shareProcessNamespace 互斥 */ -}}
  {{- $shareProcessNamespace := include "base.getValue" (list . "shareProcessNamespace") }}
  {{- $hostPID := include "base.getValue" (list . "hostPID") }}
  {{- if and $hostPID (empty $shareProcessNamespace) }}
    {{- include "base.field" (list "hostPID" $hostPID "base.bool") }}
  {{- end }}

  {{- /* hostUsers bool */ -}}
  {{- $hostUsers := include "base.getValue" (list . "hostUsers") }}
  {{- if $hostUsers }}
    {{- include "base.field" (list "hostUsers" $hostUsers "base.bool") }}
  {{- end }}

  {{- /* hostname string */ -}}
  {{- $hostname := include "base.getValue" (list . "hostname") }}
  {{- if regexMatch $const.regexRFC1035 $hostname }}
    {{- include "base.field" (list "hostname" $hostname) }}
  {{- end }}

  {{- /* hostnameOverride string */ -}}
  {{- $hostnameOverride := include "base.getValue" (list . "hostnameOverride") }}
  {{- if regexMatch $const.regexRFC1035 $hostnameOverride }}
    {{- include "base.field" (list "hostnameOverride" $hostnameOverride) }}
  {{- end }}

  {{- /* imagePullSecrets array */ -}}
  {{- $imagePullSecretsVal := include "base.getValue" (list . "imagePullSecrets") | fromYamlArray }}
  {{- $imagePullSecrets := list }}
  {{- range $imagePullSecretsVal }}
    {{- $imagePullSecrets = append $imagePullSecrets (include "definitions.LocalObjectReference" . | fromYaml) }}
  {{- end }}
  {{- if $imagePullSecrets }}
    {{- include "base.field" (list "imagePullSecrets" $imagePullSecrets "base.slice") }}
  {{- end }}

  {{- /* initContainers */ -}}
  {{- $initContainersVal := include "base.getValue" (list . "initContainers") | fromYamlArray }}
  {{- $initContainers := list }}
  {{- range $initContainersVal }}
    {{- $osVal := include "base.getValue" (list . "os") }}
    {{- $_ := set . "os" $osVal }}  {{- /* securityContext 需要用到它 */ -}}
    {{- $initContainers = append $initContainers (include "workloads.Container" . | fromYaml) }}
  {{- end }}
  {{- $initContainers = $initContainers | mustUniq | mustCompact }}
  {{- if $initContainers }}
    {{- include "base.field" (list "initContainers" $initContainers "base.slice") }}
  {{- end }}

  {{- /* nodeName string */ -}}
  {{- $nodeName := include "base.getValue" (list . "nodeName") }}
  {{- if $nodeName }}
    {{- include "base.field" (list "nodeName" $nodeName) }}
  {{- end }}

  {{- /* nodeSelector map */ -}}
  {{- $nodeSelector := include "base.getValue" (list . "nodeSelector") | fromYaml }}
  {{- if $nodeSelector }}
    {{- include "base.field" (list "nodeSelector" $nodeSelector "base.map") }}
  {{- end }}

  {{- /* os map */ -}}
  {{- $osVal := include "base.getValue" (list . "os") }}
  {{- if $osVal }}
    {{- $os := include "definitions.PodOS" $osVal | fromYaml }}
    {{- if $os }}
      {{- include "base.field" (list "os" $os "base.map") }}
    {{- end }}
  {{- end }}

  {{- /* preemptionPolicy string */ -}}
  {{- $preemptionPolicy := include "base.getValue" (list . "preemptionPolicy") }}
  {{- if $preemptionPolicy }}
    {{- include "base.field" (list "preemptionPolicy" $preemptionPolicy) }}
  {{- end }}

  {{- /* priority int */ -}}
  {{- $priority := include "base.getValue" (list . "priority") }}
  {{- if $priority }}
    {{- include "base.field" (list "priority" $priority "base.int") }}
  {{- end }}

  {{- /* priorityClassName string */ -}}
  {{- $priorityClassName := include "base.getValue" (list . "priorityClassName") }}
  {{- $priorityClassNameAllows := list "system-node-critical" "system-cluster-critical" }}
  {{- if $priorityClassName }}
    {{- include "base.field" (list "priorityClassName" $priorityClassName "base.string" $priorityClassNameAllows) }}
  {{- end }}

  {{- /* readinessGates array */ -}}
  {{- $readinessGatesVal := include "base.getValue" (list . "readinessGates") | fromYamlArray }}
  {{- $readinessGates := list }}
  {{- range $readinessGatesVal }}
    {{- $readinessGates = append $readinessGates (include "definitions.PodReadinessGate" . | fromYaml) }}
  {{- end }}
  {{- if $readinessGates }}
    {{- include "base.field" (list "readinessGates" $readinessGates "base.slice") }}
  {{- end }}

  {{- /* resources map */ -}}
  {{- $resourcesVal := include "base.getValue" (list . "resources") | fromYaml }}
  {{- if $resourcesVal }}
    {{- $resources := include "definitions.ResourceRequirements" $resourcesVal | fromYaml }}
    {{- if $resources }}
      {{- include "base.field" (list "resources" $resources "base.map") }}
    {{- end }}
  {{- end }}

  {{- /* restartPolicy string */ -}}
  {{- $restartPolicy := include "base.getValue" (list . "restartPolicy") }}
  {{- $restartPolicyAllows := list "Always" "Never" "OnFailure" }}
  {{- if $restartPolicy }}
    {{- include "base.field" (list "restartPolicy" $restartPolicy "base.string" $restartPolicyAllows) }}
  {{- end }}

  {{- /* schedulerName string */ -}}
  {{- $schedulerName := include "base.getValue" (list . "schedulerName") }}
  {{- if $schedulerName }}
    {{- include "base.field" (list "schedulerName" $schedulerName) }}
  {{- end }}

  {{- /* schedulingGates array */ -}}
  {{- $schedulingGatesVal := include "base.getValue" (list . "schedulingGates") | fromYamlArray }}
  {{- $schedulingGates := list }}
  {{- range $schedulingGatesVal }}
    {{- $schedulingGates = append $schedulingGates (include "definitions.PodSchedulingGate" . | fromYaml) }}
  {{- end }}
  {{- if $schedulingGates }}
    {{- include "base.field" (list "schedulingGates" $schedulingGates "base.slice") }}
  {{- end }}

  {{- /* securityContext */ -}}
  {{- $securityContextVal := include "base.getValue" (list . "securityContext") | fromYaml }}
  {{- if $securityContextVal }}
    {{- /* 将 os 的值传递下去 */ -}}
    {{- $_ := set $securityContextVal "os" $osVal }}
    {{- $securityContext := include "definitions.PodSecurityContext" $securityContextVal | fromYaml }}
    {{- if $securityContext }}
      {{- include "base.field" (list "securityContext" $securityContext "base.map") }}
    {{- end }}
  {{- end }}

  {{- /* serviceAccountName string */ -}}
  {{- $serviceAccountName := include "base.getValue" (list . "serviceAccountName") }}
  {{- if $serviceAccountName }}
    {{- include "base.field" (list "serviceAccountName" $serviceAccountName) }}
  {{- end }}

  {{- /* shareProcessNamespace bool 与 HostPID 互斥 */ -}}
  {{- $hostPID := include "base.getValue" (list . "hostPID") }}
  {{- $shareProcessNamespace := include "base.getValue" (list . "shareProcessNamespace") }}
  {{- if and $shareProcessNamespace (empty $hostPID) }}
    {{- include "base.field" (list "shareProcessNamespace" $shareProcessNamespace "base.bool") }}
  {{- end }}

  {{- /* subdomain string */ -}}
  {{- $subdomain := include "base.getValue" (list . "subdomain") }}
  {{- if $subdomain }}
    {{- include "base.field" (list "subdomain" $subdomain) }}
  {{- end }}

  {{- /* terminationGracePeriodSeconds int */ -}}
  {{- $terminationGracePeriodSeconds := include "base.getValue" (list . "terminationGracePeriodSeconds") }}
  {{- if $terminationGracePeriodSeconds }}
    {{- include "base.field" (list "terminationGracePeriodSeconds" $terminationGracePeriodSeconds "base.int") }}
  {{- end }}

  {{- /* tolerations */ -}}
  {{- $tolerationsVal := include "base.getValue" (list . "tolerations") | fromYamlArray }}
  {{- $tolerations := list }}
  {{- range $tolerationsVal }}
    {{- $tolerations = append $tolerations (include "definitions.Toleration" . | fromYaml) }}
  {{- end }}
  {{- if $tolerations }}
    {{- include "base.field" (list "tolerations" $tolerations "base.slice") }}
  {{- end }}

  {{- /* topologySpreadConstraints */ -}}
  {{- $topologySpreadConstraintsVal := include "base.getValue" (list . "topologySpreadConstraints") | fromYamlArray }}
  {{- $topologySpreadConstraints := list }}
  {{- range $topologySpreadConstraintsVal }}
    {{- $topologySpreadConstraints = append $topologySpreadConstraints (include "definitions.TopologySpreadConstraint" . | fromYaml) }}
  {{- end }}
  {{- if $topologySpreadConstraints }}
    {{- include "base.field" (list "topologySpreadConstraints" $topologySpreadConstraints "base.slice") }}
  {{- end }}

  {{- /* volumes array */ -}}
  {{- $volumesVal := include "base.getValue" (list . "volumes") | fromYamlArray }}
  {{- $volumes := list }}
  {{- range $volumesVal }}
    {{- $volumes = append $volumes (include "configStorage.Volume" . | fromYaml) }}
  {{- end }}
  {{- $volumes = $volumes | mustUniq | mustCompact }}
  {{- if $volumes }}
    {{- include "base.field" (list "volumes" $volumes "base.slice") }}
  {{- end }}
{{- end }}
