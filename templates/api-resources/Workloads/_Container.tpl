{{- define "workloads.Container" -}}
  {{- $const := include "base.env" "" | fromYaml }}

  {{- /* args string array */ -}}
  {{- $args := include "base.getValue" (list . "args") | fromYamlArray }}
  {{- if $args }}
    {{- include "base.field" (list "args" $args "base.slice") }}
  {{- end }}

  {{- /* command string array */ -}}
  {{- $command := include "base.getValue" (list . "command") | fromYamlArray }}
  {{- if $command }}
    {{- include "base.field" (list "command" $command "base.slice") }}
  {{- end }}

  {{- /* env array */ -}}
  {{- $envVal := include "base.getValue" (list . "env") | fromYamlArray }}
  {{- $env := list }}
  {{- range $envVal }}
    {{- $val := pick . "name" "value" "valueFrom" }}
    {{- $env = append $env (include "definitions.EnvVar" $val | fromYaml) }}
  {{- end }}
  {{- $env = $env | mustUniq | mustCompact }}
  {{- if $env }}
    {{- include "base.field" (list "env" $env "base.slice") }}
  {{- end }}

  {{- /* envFrom array */ -}}
  {{- $envFromVal := include "base.getValue" (list . "envFrom") | fromYamlArray }}
  {{- $envFrom := list }}
  {{- range $envFromVal }}
    {{- $match := regexFindAll $const.k8s.container.envFrom . -1 }}
    {{- if not $match }}
      {{- fail (printf "workloads.Container: envFrom invalid, must start with 'cm|configMap|secret'. Values: '%s'" .) }}
    {{- end }}

    {{- $val := dict }}

    {{- $_key := regexReplaceAll $const.k8s.container.envFrom . "${1}" | trim }}
    {{- $_prefix := regexReplaceAll $const.k8s.container.envFrom . "${3}" | trim }}
    {{- $_value := regexReplaceAll $const.k8s.container.envFrom . "${2} ${4}" | trim }}

    {{- $_ := set $val "prefix" $_prefix }}

    {{- if or (eq $_key "configMap") (eq $_key "cm") }}
      {{- $_ := set $val "configMapKeyRef" $_value }}

    {{- else if eq $_key "secret" }}
      {{- $_ := set $val "secretRef" $_value }}
    {{- end }}

    {{- $envFrom = append $envFrom (include "definitions.EnvFromSource" $val | fromYaml) }}
  {{- end }}
  {{- $envFrom = $envFrom | mustUniq | mustCompact }}
  {{- if $envFrom }}
    {{- include "base.field" (list "envFrom" $envFrom "base.slice") }}
  {{- end }}

  {{- /* image string */ -}}
  {{- /* 支持 image(string) 和 imageRef(map) 两种定义，且 image 优先级更高 */ -}}
  {{- $imageVal := include "base.getValue" (list . "image") }}
  {{- $imageRef := "" }}
  {{- $imageRefVal := include "base.getValue" (list . "imageRef") | fromYaml }}
  {{- if $imageRefVal }}
    {{- $_registry := get $imageRefVal "registry" | default "docker.io" | trimPrefix "/" | trimSuffix "/" }}
    {{- $_namespace := get $imageRefVal "namespace" | default "library" | trimPrefix "/" | trimSuffix "/" }}
    {{- $_repository := get $imageRefVal "repository" }}
    {{- $_tag := get $imageRefVal "tag" }}
    {{- $_digest := get $imageRefVal "digest" }}
    {{- if empty $_repository }}
      {{- fail "workloads.Container: imageRef.repository cannot be empty." }}
    {{- end }}
    {{- if and (empty $_tag) (empty $_digest) }}
      {{- $_tag = "latest" }}
    {{- end }}
    {{- if and $_digest (not (hasPrefix "sha256" $_digest)) }}
      {{- $_digest = printf "sha256:%s" $_digest }}
    {{- end }}
    {{- $image0 := join "/" (list $_registry $_namespace $_repository | compact) }}
    {{- $image1 := join ":" (list $image0 $_tag | compact) }}
    {{- $imageRef = join "@" (list $image1 $_digest | compact) }}
  {{- end }}
  {{- $image := coalesce $imageVal $imageRef }}
  {{- if $image }}
    {{- include "base.field" (list "image" $image) }}
  {{- else }}
    {{- fail "workloads.Container: image must be exists. need set 'image' or 'imageRef'." }}
  {{- end }}

  {{- /* imagePullPolicy string */ -}}
  {{- $imagePullPolicy := include "base.getValue" (list . "imagePullPolicy") }}
  {{- $imagePullPolicyAllows := list "Always" "Never" "IfNotPresent" }}
  {{- if $imagePullPolicy }}
    {{- include "base.field" (list "imagePullPolicy" $imagePullPolicy "base.string" $imagePullPolicyAllows) }}
  {{- end }}

  {{- /* lifecycle map */ -}}
  {{- $lifecycleVal := include "base.getValue" (list . "lifecycle") | fromYaml }}
  {{- if $lifecycleVal }}
    {{- $val := pick $lifecycleVal "postStart" "preStop" "stopSignal" }}
    {{- $lifecycle := include "definitions.Lifecycle" $val | fromYaml }}
    {{- if $lifecycle }}
      {{- include "base.field" (list "lifecycle" $lifecycle "base.map") }}
    {{- end }}
  {{- end }}

  {{- /* livenessProbe map */ -}}
  {{- $livenessProbeVal := include "base.getValue" (list . "livenessProbe") | fromYaml }}
  {{- if $livenessProbeVal }}
    {{- $val := pick $livenessProbeVal "exec" "failureThreshold" "grpc" "httpGet" "initialDelaySeconds" "periodSeconds" "successThreshold" "tcpSocket" "terminationGracePeriodSeconds" "timeoutSeconds" }}
    {{- $_ := set $val "_type" "liveness" }}
    {{- $livenessProbe := include "definitions.Probe" $val | fromYaml }}
    {{- if $livenessProbe }}
      {{- include "base.field" (list "livenessProbe" $livenessProbe "base.map") }}
    {{- end }}
  {{- end }}

  {{- /* name string */ -}}
  {{- $name := include "base.getValue" (list . "name") }}
  {{- if (include "base.rfc1035" $name) }}
    {{- include "base.field" (list "name" $name) }}
  {{- end }}

  {{- /* ports array */ -}}
  {{- $portsVal := include "base.getValue" (list . "ports") | fromYamlArray }}
  {{- $ports := list }}
  {{- range $portsVal }}
    {{- /* 此处与其他模板定义处理方式不同 */ -}}
    {{- /* 当只有一个值是，一般来说它是 containerPort */ -}}
    {{- /* 此时在内部会被识别为 float64 类型，但实际上此处应该处理 string 类型 */ -}}
    {{- /* 所以，在此处将上下文赋于 $root 以方例单独处理 float64 类型 */ -}}
    {{- $root := . }}
    {{- if kindIs "float64" . }}
      {{- $root = include "base.int" . }}
    {{- end }}

    {{- $match := regexFindAll $const.k8s.container.ports $root -1 }}
    {{- if not $match }}
      {{- fail (printf "workloads.Container: ports invalid. Values: %s, format: '[hostIP:][hostPort:]containerPort[/protocol][#name]'" .) }}
    {{- end }}

    {{- $hostIP := regexReplaceAll $const.k8s.container.ports $root "${2}" | trim }}
    {{- $hostPort := regexReplaceAll $const.k8s.container.ports $root "${3}" | trim }}
    {{- $containerPort := regexReplaceAll $const.k8s.container.ports $root "${4}" | trim }}
    {{- $protocol := regexReplaceAll $const.k8s.container.ports $root "${5}" | trim | upper }}
    {{- $name := regexReplaceAll $const.k8s.container.ports $root "${6}" | trim }}
    {{- $val := dict "hostIP" $hostIP "hostPort" $hostPort "containerPort" $containerPort "protocol" $protocol "name" $name }}

    {{- $ports = append $ports (include "definitions.ContainerPort" $val | fromYaml) }}
  {{- end }}
  {{- $ports = $ports | mustUniq | mustCompact }}
  {{- if $ports }}
    {{- include "base.field" (list "ports" $ports "base.slice") }}
  {{- end }}

  {{- /* readinessProbe map */ -}}
  {{- $readinessProbeVal := include "base.getValue" (list . "readinessProbe") | fromYaml }}
  {{- if $readinessProbeVal }}
    {{- $val := pick $readinessProbeVal "exec" "failureThreshold" "grpc" "httpGet" "initialDelaySeconds" "periodSeconds" "successThreshold" "tcpSocket" "terminationGracePeriodSeconds" "timeoutSeconds" }}
    {{- $_ := set $val "_type" "readiness" }}
    {{- $readinessProbe := include "definitions.Probe" $val | fromYaml }}
    {{- if $readinessProbe }}
      {{- include "base.field" (list "readinessProbe" $readinessProbe "base.map") }}
    {{- end }}
  {{- end }}

  {{- /* resizePolicy array */ -}}
  {{- $resizePolicyVal := include "base.getValue" (list . "resizePolicy") | fromYamlArray }}
  {{- $resizePolicy := list }}
  {{- range $resizePolicyVal }}
    {{- $match := regexFindAll $const.k8s.container.resizePolicy . -1 }}
    {{- if not $match }}
      {{- fail (printf "workloads.Container: resizePolicy invalid. Values: %s, format: 'resourceName [restartPolicy]'" .) }}
    {{- end }}

    {{- $resourceName := regexReplaceAll $const.k8s.container.resizePolicy . "${1}" | trim | lower }}
    {{- $resourcePolicy := regexReplaceAll $const.k8s.container.resizePolicy . "${2}" | trim }}
    {{- $val := dict "resourceName" $resourceName "resourcePolicy" $resourcePolicy }}

    {{- $resizePolicy = append $resizePolicy (include "definitions.ContainerResizePolicy" $val | fromYaml) }}
  {{- end }}
  {{- $resizePolicy = $resizePolicy | mustUniq | mustCompact }}
  {{- if $resizePolicy }}
    {{- include "base.field" (list "resizePolicy" $resizePolicy "base.slice") }}
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

  {{- /* restartPolicyRules array */ -}}
  {{- $restartPolicyRulesVal := include "base.getValue" (list . "restartPolicyRules") | fromYamlArray }}
  {{- $restartPolicyRules := list }}
  {{- range $restartPolicyRulesVal }}
    {{- $match := regexFindAll $const.k8s.container.restartPolicyRules . -1 }}
    {{- if not $match }}
      {{- fail (printf "workloads.Container: restartPolicyRules invalid. Values: %s, format: 'restart <in|notin> (codeNumber, ...)'" .) }}
    {{- end }}

    {{- $action := regexReplaceAll $const.k8s.container.restartPolicyRules . "${1}" | trim | title }}
    {{- $exitCodes := regexReplaceAll $const.k8s.container.restartPolicyRules . "${2} (${3})" | trim }}
    {{- $val := dict "action" $action "exitCodes" $exitCodes }}

    {{- $restartPolicyRules = append $restartPolicyRules (include "definitions.ContainerRestartRule" $val | fromYaml) }}
  {{- end }}
  {{- $restartPolicyRules = $restartPolicyRules | mustUniq | mustCompact }}
  {{- if gt (len $restartPolicyRules) 20 }}
    {{- $restartPolicyRules = slice $restartPolicyRules 0 20 }}
  {{- end }}
  {{- if $restartPolicyRules }}
    {{- include "base.field" (list "restartPolicyRules" $restartPolicyRules "base.slice") }}
  {{- end }}

  {{- /* restartPolicy string */ -}}
  {{- $restartPolicy := include "base.getValue" (list . "restartPolicy") }}
  {{- $restartPolicyAllows := list "Always" "Never" "OnFailure" }}
  {{- if and $restartPolicyRules (not (has $restartPolicy $restartPolicyAllows)) }}
    {{- fail "container must set restartPolicy explicitly." }}
  {{- end }}
  {{- if $restartPolicy }}
    {{- include "base.field" (list "restartPolicy" $restartPolicy "base.string" $restartPolicyAllows) }}
  {{- end }}

  {{- /* securityContext map */ -}}
  {{- $securityContextVal := include "base.getValue" (list . "securityContext") | fromYaml }}
  {{- if $securityContextVal }}
    {{- $val := pick $securityContextVal "allowPrivilegeEscalation" "appArmorProfile" "capabilities" "privileged" "procMount" "readOnlyRootFilesystem" "runAsGroup" "runAsNonRoot" "runAsUser" "seLinuxOptions" "seccompProfile" "windowsOptions" }}
    {{- /* 将 os 的值传递下去 */ -}}
    {{- $_os := include "base.getValue" (list . "os") }}
    {{- $_ := set $val "os" $_os }}
    {{- $securityContext := include "definitions.SecurityContext" $val | fromYaml }}
    {{- if $securityContext }}
      {{- include "base.field" (list "securityContext" $securityContext "base.map") }}
    {{- end }}
  {{- end }}

  {{- /* startupProbe map */ -}}
  {{- $startupProbeVal := include "base.getValue" (list . "startupProbe") | fromYaml }}
  {{- if $startupProbeVal }}
    {{- $val := pick $startupProbeVal "exec" "failureThreshold" "grpc" "httpGet" "initialDelaySeconds" "periodSeconds" "successThreshold" "tcpSocket" "terminationGracePeriodSeconds" "timeoutSeconds" }}
    {{- $_ := set $val "_type" "startup" }}
    {{- $startupProbe := include "definitions.Probe" $val | fromYaml }}
    {{- if $startupProbe }}
      {{- include "base.field" (list "startupProbe" $startupProbe "base.map") }}
    {{- end }}
  {{- end }}

  {{- /* stdin bool */ -}}
  {{- $stdin := include "base.getValue" (list . "stdin") }}
  {{- if $stdin }}
    {{- include "base.field" (list "stdin" $stdin "base.bool") }}
  {{- end }}

  {{- /* stdinOnce bool */ -}}
  {{- $stdinOnce := include "base.getValue" (list . "stdinOnce") }}
  {{- if $stdinOnce }}
    {{- include "base.field" (list "stdinOnce" $stdinOnce "base.bool") }}
  {{- end }}

  {{- /* terminationMessagePath string */ -}}
  {{- $terminationMessagePath := include "base.getValue" (list . "terminationMessagePath") }}
  {{- if $terminationMessagePath }}
    {{- include "base.field" (list "terminationMessagePath" $terminationMessagePath "base.absPath") }}
  {{- end }}

  {{- /* terminationMessagePolicy string */ -}}
  {{- $terminationMessagePolicy := include "base.getValue" (list . "terminationMessagePolicy") }}
  {{- $terminationMessagePolicyAllows := list "FallbackToLogsOnError" "File" }}
  {{- if $terminationMessagePolicy }}
    {{- include "base.field" (list "terminationMessagePolicy" $terminationMessagePolicy "base.string" $terminationMessagePolicyAllows) }}
  {{- end }}

  {{- /* tty bool */ -}}
  {{- $tty := include "base.getValue" (list . "tty") }}
  {{- if $tty }}
    {{- include "base.field" (list "tty" $tty "base.bool") }}
  {{- end }}

  {{- /* volumeDevices array */ -}}
  {{- $volumeDevicesVal := include "base.getValue" (list . "volumeDevices") | fromYamlArray }}
  {{- $volumeDevices := list }}
  {{- range $volumeDevicesVal }}
    {{- $match := regexFindAll $const.k8s.volume.device . -1 }}
    {{- if not $match }}
      {{- fail (printf "volumeDevice: error. Values: '%s', format: 'name devicePath'" .) }}
    {{- end }}

    {{- $name := regexReplaceAll $const.k8s.volume.device . "${1}" | trim }}
    {{- $devicePath := regexReplaceAll $const.k8s.volume.device . "${2}" | trim }}
    {{- $val := dict "name" $name "devicePath" $devicePath }}

    {{- $volumeDevices = append $volumeDevices (include "definitions.VolumeDevice" $val | fromYaml) }}
  {{- end }}
  {{- $volumeDevices = $volumeDevices | mustUniq | mustCompact }}
  {{- if $volumeDevices }}
    {{- include "base.field" (list "volumeDevices" $volumeDevices "base.slice") }}
  {{- end }}

  {{- /* volumeMounts array */ -}}
  {{- $volumeMountsVal := include "base.getValue" (list . "volumeMounts") | fromYamlArray }}
  {{- $volumeMounts := list }}
  {{- range $volumeMountsVal }}
    {{- $match := regexFindAll $const.k8s.volume.mount . -1 }}
    {{- if not $match }}
      {{- fail (printf "workloads.Container: volumeMounts invalid. Values: %s, format: 'name mountPath [subPath] [subPathExpr] [readOnly] [recursiveReadOnly] [mountPropagation]'" .) }}
    {{- end }}

    {{- $name := regexReplaceAll $const.k8s.volume.mount . "${1}" | trim }}
    {{- $mountPath := regexReplaceAll $const.k8s.volume.mount . "${2}" | trim }}
    {{- $subPath := regexReplaceAll $const.k8s.volume.mount . "${3}" | trim }}
    {{- $subPathExpr := regexReplaceAll $const.k8s.volume.mount . "${4}" | trim }}
    {{- $readOnly := regexReplaceAll $const.k8s.volume.mount . "${5}" | trim }}
    {{- $recursiveReadOnly := regexReplaceAll $const.k8s.volume.mount . "${6}" | trim }}
    {{- $mountPropagation := regexReplaceAll $const.k8s.volume.mount . "${7}" | trim }}

    {{- $val := dict "name" $name "mountPath" $mountPath "subPath" $subPath "subPathExpr" $subPathExpr "readOnly" $readOnly "recursiveReadOnly" $recursiveReadOnly "mountPropagation" $mountPropagation }}

    {{- $volumeMounts = append $volumeMounts (include "definitions.VolumeMount" $val | fromYaml) }}
  {{- end }}
  {{- $volumeMounts = $volumeMounts | mustUniq | mustCompact }}
  {{- if $volumeMounts }}
    {{- include "base.field" (list "volumeMounts" $volumeMounts "base.slice") }}
  {{- end }}

  {{- /* workingDir string */ -}}
  {{- $workingDir := include "base.getValue" (list . "workingDir") }}
  {{- if $workingDir }}
    {{- include "base.field" (list "workingDir" $workingDir "base.absPath") }}
  {{- end }}
{{- end }}
