{{- define "workloads.PodSpec" -}}
  {{- $const := include "base.env" "" | fromYaml }}

  {{- /* activeDeadlineSeconds int */ -}}
  {{- $activeDeadlineSeconds := include "base.getValue" (list . "activeDeadlineSeconds") }}
  {{- if $activeDeadlineSeconds }}
    {{- include "base.field" (list "activeDeadlineSeconds" $activeDeadlineSeconds "base.int") }}
  {{- end }}

  {{- /* affinity map */ -}}
  {{- /* 由 nodeAffinity podAffinity podAntiAffinity 三个定义完成 */ -}}
  {{- $nodeAffinity := include "base.getValue" (list . "nodeAffinity") | fromYaml }}
  {{- $podAffinity := include "base.getValue" (list . "podAffinity") | fromYaml }}
  {{- $podAntiAffinity := include "base.getValue" (list . "podAntiAffinity") | fromYaml }}
  {{- $val := dict "nodeAffinity" $nodeAffinity "podAffinity" $podAffinity "podAntiAffinity" $podAntiAffinity }}
  {{- $affinity := include "definitions.Affinity" $val | fromYaml }}
  {{- if $affinity }}
    {{- include "base.field" (list "affinity" $affinity "base.map") }}
  {{- end }}

  {{- /* automountServiceAccountToken bool */ -}}
  {{- $automountServiceAccountToken := include "base.getValue" (list . "automountServiceAccountToken" "toString") }}
  {{- if $automountServiceAccountToken }}
    {{- include "base.field" (list "automountServiceAccountToken" $automountServiceAccountToken "base.bool") }}
  {{- end }}

  {{- /* containers array */ -}}
  {{- $containersVal := include "base.getValue" (list . "containers") | fromYamlArray }}
  {{- $_os := include "base.getValue" (list . "os") }}
  {{- $containers := list }}
  {{- range $containersVal }}
    {{- $_ := set . "os" $_os }}  {{- /* securityContext 需要用到它 */ -}}
    {{- $_ := set . "Files" $.Files }}
    {{- $_ := set . "Values" $.Values }}
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
    {{- if not (regexMatch $const.k8s.hostAlias .) }}
      {{- fail (printf "workloads.PodSpec: hostAlias invalid. Values: '%s'" .) }}
    {{- end }}

    {{- $splitVal := regexSplit $const.split.space . -1 }}
    {{- $val := dict "ip" (first $splitVal) "hostnames" (rest $splitVal) }}

    {{- $hostAliases = append $hostAliases (include "definitions.HostAlias" $val | fromYaml) }}
  {{- end }}
  {{- $hostAliases = $hostAliases | mustUniq | mustCompact }}
  {{- if $hostAliases }}
    {{- include "base.field" (list "hostAlias" $hostAliases "base.slice") }}
  {{- end }}

  {{- /* hostNetwork bool */ -}}
  {{- $_hostnameOverride := include "base.getValue" (list . "hostnameOverride") }}
  {{- if not (regexMatch $const.rfc.RFC1035 $_hostnameOverride) }}
    {{- $hostNetwork := include "base.getValue" (list . "hostNetwork") }}
    {{- if $hostNetwork }}
      {{- include "base.field" (list "hostNetwork" $hostNetwork "base.bool") }}
    {{- end }}
  {{- end }}

  {{- /* hostPID bool 与 shareProcessNamespace 互斥 */ -}}
  {{- $_shareProcessNamespace := include "base.getValue" (list . "shareProcessNamespace") }}
  {{- $hostPID := include "base.getValue" (list . "hostPID") }}
  {{- if and $hostPID (empty $_shareProcessNamespace) }}
    {{- include "base.field" (list "hostPID" $hostPID "base.bool") }}
  {{- end }}

  {{- /* hostUsers bool */ -}}
  {{- /* 需要能显示指定 false */ -}}
  {{- $hostUsers := include "base.getValue" (list . "hostUsers" "toString") }}
  {{- if $hostUsers }}
    {{- include "base.field" (list "hostUsers" $hostUsers) }}
  {{- end }}

  {{- /* hostname string */ -}}
  {{- $hostname := include "base.getValue" (list . "hostname") }}
  {{- if $hostname }}
    {{- include "base.field" (list "hostname" $hostname "base.rfc1035") }}
  {{- end }}

  {{- /* hostnameOverride string */ -}}
  {{- $hostnameOverride := include "base.getValue" (list . "hostnameOverride") }}
  {{- if $hostnameOverride }}
    {{- include "base.field" (list "hostnameOverride" $hostnameOverride "base.rfc1035") }}
  {{- end }}

  {{- /* imagePullSecrets array */ -}}
  {{- $imagePullSecretsVal := include "base.getValue" (list . "imagePullSecrets") | fromYamlArray }}
  {{- $imagePullSecrets := list }}
  {{- range $imagePullSecretsVal }}
    {{- $val := dict "name" . }}
    {{- $imagePullSecrets = append $imagePullSecrets (include "definitions.LocalObjectReference" $val | fromYaml) }}
  {{- end }}
  {{- $imagePullSecrets = $imagePullSecrets | mustUniq | mustCompact }}
  {{- if $imagePullSecrets }}
    {{- include "base.field" (list "imagePullSecrets" $imagePullSecrets "base.slice") }}
  {{- end }}

  {{- /* initContainers array */ -}}
  {{- $initContainersVal := include "base.getValue" (list . "initContainers") | fromYamlArray }}
  {{- $_os := include "base.getValue" (list . "os") }}
  {{- $initContainers := list }}
  {{- range $initContainersVal }}
    {{- $_ := set . "os" $_os }}  {{- /* securityContext 需要用到它 */ -}}
    {{- $_ := set . "Files" $.Files }}
    {{- $_ := set . "Values" $.Values }}
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
    {{- $val := dict "name" $osVal }}
    {{- $os := include "definitions.PodOS" $val | fromYaml }}
    {{- if $os }}
      {{- include "base.field" (list "os" $os "base.map") }}
    {{- end }}
  {{- end }}

  {{- /* preemptionPolicy string */ -}}
  {{- $preemptionPolicy := include "base.getValue" (list . "preemptionPolicy") }}
  {{- $preemptionPolicyAllows := list "Never" "PreemptLowerPriority" }}
  {{- if $preemptionPolicy }}
    {{- include "base.field" (list "preemptionPolicy" $preemptionPolicy "base.string" $preemptionPolicyAllows) }}
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
    {{- $val := dict "conditionType" . }}
    {{- $readinessGates = append $readinessGates (include "definitions.PodReadinessGate" $val | fromYaml) }}
  {{- end }}
  {{- $readinessGates = $readinessGates | mustUniq | mustCompact }}
  {{- if $readinessGates }}
    {{- include "base.field" (list "readinessGates" $readinessGates "base.slice") }}
  {{- end }}

  {{- /* resources map */ -}}
  {{- $resourcesVal := include "base.getValue" (list . "resources") | fromYaml }}
  {{- if $resourcesVal }}
    {{- $val := pick $resourcesVal "limits" "requests" }}
    {{- $resources := include "definitions.ResourceRequirements" $val | fromYaml }}
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
    {{- $val := dict "name" . }}
    {{- $schedulingGates = append $schedulingGates (include "definitions.PodSchedulingGate" $val | fromYaml) }}
  {{- end }}
  {{- $schedulingGates = $schedulingGates | mustUniq | mustCompact }}
  {{- if $schedulingGates }}
    {{- include "base.field" (list "schedulingGates" $schedulingGates "base.slice") }}
  {{- end }}

  {{- /* securityContext */ -}}
  {{- $securityContextVal := include "base.getValue" (list . "securityContext") | fromYaml }}
  {{- $_os := include "base.getValue" (list . "os") }}
  {{- if $securityContextVal }}
    {{- $val := pick . "appArmorProfile" "fsGroup" "fsGroupChangePolicy" "runAsGroup" "runAsNonRoot" "runAsUser" "seLinuxChangePolicy" "seLinuxOptions" "seccompProfile" "supplementalGroups" "supplementalGroupsPolicy" "sysctls" "windowsOptions" }}
    {{- /* 将 os 的值传递下去 */ -}}
    {{- $_ := set $val "os" $_os }}
    {{- $securityContext := include "definitions.PodSecurityContext" $val | fromYaml }}
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
  {{- $_hostPID := include "base.getValue" (list . "hostPID") }}
  {{- $shareProcessNamespace := include "base.getValue" (list . "shareProcessNamespace") }}
  {{- if and $shareProcessNamespace (empty $_hostPID) }}
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

  {{- /* tolerations array */ -}}
  {{- $tolerationsVal := include "base.getValue" (list . "tolerations") | fromYamlArray }}
  {{- $tolerations := list }}
  {{- range $tolerationsVal }}
    {{- $val := pick . "effect" "key" "operator" "tolerationSeconds" "value" }}
    {{- $tolerations = append $tolerations (include "definitions.Toleration" $val | fromYaml) }}
  {{- end }}
  {{- if $tolerations }}
    {{- include "base.field" (list "tolerations" $tolerations "base.slice") }}
  {{- end }}

  {{- /* topologySpreadConstraints array */ -}}
  {{- $topologySpreadConstraintsVal := include "base.getValue" (list . "topologySpreadConstraints") | fromYamlArray }}
  {{- $topologySpreadConstraints := list }}
  {{- range $topologySpreadConstraintsVal }}
    {{- $val := pick . "labelSelector" "matchLabelKeys" "maxSkew" "minDomains" "nodeAffinityPolicy" "nodeTaintsPolicy" "topologyKey" "whenUnsatisfiable" }}
    {{- $topologySpreadConstraints = append $topologySpreadConstraints (include "definitions.TopologySpreadConstraint" $val | fromYaml) }}
  {{- end }}
  {{- if $topologySpreadConstraints }}
    {{- include "base.field" (list "topologySpreadConstraints" $topologySpreadConstraints "base.slice") }}
  {{- end }}

  {{- /* volumes array */ -}}
  {{- $volumesVal := include "base.getValue" (list . "volumes") | fromYamlArray }}
  {{- $volumes := list }}
  {{- range $volumesVal }}
    {{- if not (regexMatch $const.k8s.volume.volumes .) }}
      {{- fail (printf "workloads.PodSpec: volume invalid. Values: '%s'." .) }}
    {{- end }}
    {{- $volumeType := regexReplaceAll $const.k8s.volume.volumes . "${1}" | trim }}
    {{- $name := regexReplaceAll $const.k8s.volume.volumes . "${2}" | trim }}
    {{- $volumeData := regexReplaceAll $const.k8s.volume.volumes . "${3}" | trim }}
    {{- $val := dict "volumeType" $volumeType "name" $name "volumeData" $volumeData }}
    {{- $volumes = append $volumes (include "configStorage.Volume" $val | fromYaml) }}
  {{- end }}
  {{- $volumes = $volumes | mustUniq | mustCompact }}
  {{- if $volumes }}
    {{- include "base.field" (list "volumes" $volumes "base.slice") }}
  {{- end }}
{{- end }}
