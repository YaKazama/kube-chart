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
  {{- /* envFileRefs array */ -}}
  {{- /*
    # 读取内容后与 env 合并
    # 优先级 env < envFileRefs
  */ -}}
  {{- $envVal := include "base.getValue" (list . "env") | fromYamlArray }}
  {{- $env := list }}
  {{- range $envVal }}
    {{- $val := pick . "name" "value" "valueFrom" }}
    {{- $env = append $env (include "definitions.EnvVar" $val | fromYaml) }}
  {{- end }}
  {{- /* 处理 envFileRefs 将数据追加到 env 中 */ -}}
  {{- $envFileRefs := include "base.getValue" (list . "envFileRefs") | fromYamlArray }}
  {{- range $envFileRefs }}
    {{- $filePath := include "base.getValue" (list . "filePath") }}
    {{- $filePath = include "base.relPath" $filePath }}
    {{- if empty $filePath }}
      {{- fail "workloads.Container: envFileRefs[].filePath cannot be empty" }}
    {{- end }}
    {{- $content := $.Files.Get $filePath }}

    {{- $fieldPaths := include "base.getValue" (list . "fieldPaths") | fromYamlArray }}
    {{- /* fieldPaths 为空，尝试加载整个文件 */ -}}
    {{- if empty $fieldPaths }}
      {{- $contentFormat := $content | fromYamlArray }}
      {{- $isNotSlice := include "base.isFromYamlArrayError" $contentFormat }}
      {{- /* 文件中的数据是 list 才追加 */ -}}
      {{- if eq $isNotSlice "false" }}
        {{- range $contentFormat }}
          {{- $env = append $env (include "definitions.EnvVar" . | fromYaml) }}
        {{- end }}
      {{- end }}

    {{- /* 通过 fieldPaths 取值 */ -}}
    {{- else }}
      {{- range $fieldPaths }}
        {{- $contentFormat := $content | fromYaml }}
        {{- $isNotMap := include "base.isFromYamlError" $contentFormat }}
        {{- /* 文件中的数据是 map 才追加 */ -}}
        {{- if eq $isNotMap "false" }}
          {{- $val := include "base.map.dig" (dict "m" $contentFormat "k" .) | fromYamlArray }}
          {{- $isNotSlice := include "base.isFromYamlArrayError" $val }}
          {{- /* 文件中的数据是 list 才追加 */ -}}
          {{- if eq $isNotSlice "false" }}
            {{- range $val }}
              {{- $env = concat $env (include "definitions.EnvVar" . | fromYaml) }}
            {{- end }}
          {{- end }}
        {{- end }}
      {{- end }}
    {{- end }}
  {{- end }}
  {{- $env = $env | mustUniq | mustCompact }}
  {{- if $env }}
    {{- include "base.field" (list "env" $env "base.slice") }}
  {{- end }}

  {{- /* envFrom array */ -}}
  {{- /* envFromFileRefs array */ -}}
  {{- /*
    # 读取内容后与 envFrom 合并
    # 优先级 envFrom < envFromFileRefs
  */ -}}
  {{- $envFromVal := include "base.getValue" (list . "envFrom") | fromYamlArray }}
  {{- $envFrom := list }}
  {{- range $envFromVal }}
    {{- $envFrom = append $envFrom (include "workloads.Container.envFrom" . | fromYaml) }}
  {{- end }}
  {{- /* 处理 envFromFileRefs 将数据追加到 envFrom 中 */ -}}
  {{- $envFromFileRefs := include "base.getValue" (list . "envFromFileRefs") | fromYamlArray }}
  {{- range $envFromFileRefs }}
    {{- $filePath := include "base.getValue" (list . "filePath") }}
    {{- $filePath = include "base.relPath" $filePath }}
    {{- if empty $filePath }}
      {{- fail "workloads.Container: envFileRefs[].filePath cannot be empty" }}
    {{- end }}
    {{- $content := $.Files.Get $filePath }}

    {{- $fieldPaths := include "base.getValue" (list . "fieldPaths") | fromYamlArray }}
    {{- /* fieldPaths 为空，尝试加载整个文件 */ -}}
    {{- if empty $fieldPaths }}
      {{- /* 文件中的数据是 list 才追加 */ -}}
      {{- $contentFormat := $content | fromYamlArray }}
      {{- $isNotSlice := include "base.isFromYamlArrayError" $contentFormat }}
      {{- if eq $isNotSlice "false" }}
        {{- range $contentFormat }}
          {{- $envFrom = append $envFrom (include "workloads.Container.envFrom" . | fromYaml) }}
        {{- end }}
      {{- end }}

    {{- /* 通过 fieldPaths 取值 */ -}}
    {{- else }}
      {{- range $fieldPaths }}
        {{- $contentFormat := $content | fromYaml }}
        {{- $isNotMap := include "base.isFromYamlError" $contentFormat }}
        {{- /* 文件中的数据是 map 才追加 */ -}}
        {{- if eq $isNotMap "false" }}
          {{- $val := include "base.map.dig" (dict "m" $contentFormat "k" .) | fromYamlArray }}
          {{- $isNotSlice := include "base.isFromYamlArrayError" $val }}
          {{- /* 文件中的数据是 list 才追加 */ -}}
          {{- if eq $isNotSlice "false" }}
            {{- range $val }}
              {{- $envFrom = append $envFrom (include "workloads.Container.envFrom" . | fromYaml) }}
            {{- end }}
          {{- end }}
        {{- end }}
      {{- end }}
    {{- end }}
  {{- end }}
  {{- $envFrom = $envFrom | mustUniq | mustCompact }}
  {{- if $envFrom }}
    {{- include "base.field" (list "envFrom" $envFrom "base.slice") }}
  {{- end }}

  {{- /* image string */ -}}
  {{- /* 支持 image(string) 和 imageRef(map) 两种定义，且 imageRef 优先级更高 */ -}}
  {{- $image := include "workloads.Container.image" . }}
  {{- if $image }}
    {{- include "base.field" (list "image" $image) }}
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
  {{- /* resourcesFileRefs array */ -}}
  {{- /*
    # 读取内容后与 resources 合并
    # 优先级 resources < resourcesFileRefs 且 resourcesFileRefs 按序覆盖
  */ -}}
  {{- $resourcesVal := include "base.getValue" (list . "resources") | fromYaml }}
  {{- $resources := dict }}
  {{- if $resourcesVal }}
    {{- $val := pick $resourcesVal "limits" "requests" }}
    {{- $resources = include "definitions.ResourceRequirements" $val | fromYaml }}
  {{- end }}
  {{- /* 处理 resourcesFileRefs 将数据追加到 resources 中 */ -}}
  {{- $resourcesFileRefs := include "base.getValue" (list . "resourcesFileRefs") | fromYamlArray }}
  {{- range $resourcesFileRefs }}
    {{- $filePath := include "base.getValue" (list . "filePath") }}
    {{- $filePath = include "base.relPath" $filePath }}
    {{- if empty $filePath }}
      {{- fail "workloads.Container: envFileRefs[].filePath cannot be empty" }}
    {{- end }}
    {{- $content := $.Files.Get $filePath }}

    {{- $fieldPaths := include "base.getValue" (list . "fieldPaths") | fromYamlArray }}
    {{- /* fieldPaths 为空，尝试加载整个文件 */ -}}
    {{- if empty $fieldPaths }}
      {{- /* 文件中的数据是 map 才追加 */ -}}
      {{- $contentFormat := $content | fromYaml }}
      {{- $isNotMap := include "base.isFromYamlError" $contentFormat }}
      {{- if eq $isNotMap "false" }}
        {{- $val := pick $contentFormat "limits" "requests" }}
        {{- $resources = mergeOverwrite $resources (include "definitions.ResourceRequirements" $val | fromYaml) }}
      {{- end }}

    {{- /* 通过 fieldPaths 取值 */ -}}
    {{- else }}
      {{- range $fieldPaths }}
        {{- $contentFormat := $content | fromYaml }}
        {{- $isNotMap := include "base.isFromYamlError" $contentFormat }}
        {{- if eq $isNotMap "false" }}
          {{- $_val := include "base.map.dig" (dict "m" $contentFormat "k" .) | fromYaml }}
          {{- $val := pick $_val "limits" "requests" }}
          {{- $resources = mergeOverwrite $resources (include "definitions.ResourceRequirements" $val | fromYaml) }}
        {{- end }}
      {{- end }}
    {{- end }}
  {{- end }}
  {{- if $resources }}
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

{{- /* envFrom 处理模板 返回 list */ -}}
{{- define "workloads.Container.envFrom" -}}
  {{- $const := include "base.env" "" | fromYaml }}

  {{- $val := dict }}
  {{- if kindIs "string" . }}
    {{- $match := regexFindAll $const.k8s.container.envFrom . -1 }}
    {{- if not $match }}
      {{- fail (printf "workloads.Container.envFrom: invalid, must start with 'cm|configMap|secret'. Values: '%s'" .) }}
    {{- end }}

    {{- $_key := regexReplaceAll $const.k8s.container.envFrom . "${1}" | lower | trim }}
    {{- $_prefix := regexReplaceAll $const.k8s.container.envFrom . "${3}" | trim }}
    {{- $_value := regexReplaceAll $const.k8s.container.envFrom . "${2} ${4}" | trim }}

    {{- $val = merge $val (dict "prefix" $_prefix) }}
    {{- if or (eq $_key "configMap") (eq $_key "configmap") (eq $_key "cm") }}
      {{- $val = merge (dict "configMapRef" $_value) }}
    {{- else if eq $_key "secret" }}
      {{- $val = merge (dict "secretRef" $_value) }}
    {{- end }}

  {{- else if kindIs "map" . }}
    {{- $val = . }}
  {{- end }}
  {{- include "definitions.EnvFromSource" $val | fromYaml | toYamlPretty }}
{{- end }}

{{- /* 获取最终的镜像地址（优先 imageRef，其次 image） */ -}}
{{- define "workloads.Container.image" -}}
  {{- /* 处理 imageFileRefs 获取外部候选值 */ -}}
  {{- $imageFileRefs := include "base.getValue" (list . "imageFileRefs") | fromYamlArray }}
  {{- $extImage := "" }}
  {{- range $imageFileRefs }}
    {{- $filePath := include "base.getValue" (list . "filePath") }}
    {{- $filePath = include "base.relPath" $filePath }}
    {{- if empty $filePath }}
      {{- fail "workloads.Container.image: envFileRefs[].filePath cannot be empty" }}
    {{- end }}
    {{- $content := $.Files.Get $filePath }}

    {{- $fieldPaths := include "base.getValue" (list . "fieldPaths") | fromYamlArray }}
    {{- /* fieldPaths 为空，尝试加载整个文件 */ -}}
    {{- if empty $fieldPaths }}
      {{- $contentFormat := $content | fromYaml }}
      {{- $isNotMap := include "base.isFromYamlError" $contentFormat }}
      {{- $isNotSlice := include "base.isFromYamlArrayError" ($content | fromYamlArray) }}
      {{- /* map 调 workloads.Container.imageRef 处理 */ -}}
      {{- if eq $isNotMap "false" }}
        {{- $extImage = include "workloads.Container.imageRef" $contentFormat }}
      {{- /* slice 什么都不做 会报错 */ -}}
      {{- else if eq $isNotSlice "false" }}
        {{- fail (printf "workloads.Container.image: imageFileRefs invalid. Values: '%v', File: '%v'" $content $filePath) }}
      {{- /* 其他情况当作字符串处理 */ -}}
      {{- else }}
        {{- $extImage = $content }}
      {{- end }}

    {{- /* 通过 fieldPaths 取值 */ -}}
    {{- else }}
      {{- range $fieldPaths }}
        {{- $contentFormat := $content | fromYaml }}
        {{- $isNotMap := include "base.isFromYamlError" $contentFormat }}
        {{- $isNotSlice := include "base.isFromYamlArrayError" ($content | fromYamlArray) }}
        {{- /* map 调 workloads.Container.imageRef 处理 */ -}}
        {{- if eq $isNotMap "false" }}
          {{- $_val := include "base.map.dig" (dict "m" $contentFormat "k" .) }}
          {{- $val := $_val | fromYaml }}
          {{- $isNotMap := include "base.isFromYamlError" $val }}
          {{- $isNotSlice := include "base.isFromYamlArrayError" ($_val | fromYamlArray) }}
          {{- if eq $isNotMap "false" }}
            {{- $extImage = include "workloads.Container.imageRef" $val }}
          {{- else if eq $isNotSlice "false" }}
            {{- fail (printf "workloads.Container.image: imageFileRefs invalid. Values: '%v', fieldPath: '%v', File: '%v'" $content . $filePath) }}
          {{- else }}
            {{- $extImage = $_val }}
          {{- end }}

        {{- /* slice 什么都不做 会报错 */ -}}
        {{- else if eq $isNotSlice "false" }}
          {{- fail (printf "workloads.Container.image: imageFileRefs invalid. Values: '%v', fieldPath: '%v', File: '%v'" $content . $filePath) }}
        {{- /* 其他情况当作字符串处理 */ -}}
        {{- else }}
          {{- $extImage = $content }}
        {{- end }}
      {{- end }}
    {{- end }}
  {{- end }}

  {{- /* 获取内部 image 原始值 */ -}}
  {{- $image := include "base.getValue" (list . "image") }}

  {{- /* 解析内部 imageRef 并拼接 */ -}}
  {{- $imageRefVal := include "base.getValue" (list . "imageRef") | fromYaml }}
  {{- $imageRef := "" }}
  {{- if $imageRefVal }}
    {{- $imageRef = include "workloads.Container.imageRef" $imageRefVal }}
  {{- end }}

  {{- /* 按优先级取非空值 */ -}}
  {{- $fullImage := coalesce $extImage $imageRef $image }}

  {{- /* 最终校验 */ -}}
  {{- if empty $fullImage }}
    {{- fail "workloads.Container: image must be set (either 'image' or 'imageRef' is required)" }}
  {{- end }}

  {{- /* 返回最终值 */ -}}
  {{- $fullImage }}
{{- end }}

{{- /* 解析 imageRef 为完整的镜像地址 */ -}}
{{- define "workloads.Container.imageRef" -}}
  {{- /* 1. 提取字段并处理默认值 */ -}}
  {{- $registry := get . "registry" }}
  {{- if $registry }}
    {{- $registry = $registry | trimPrefix "/" | trimSuffix "/" }}
  {{- end }}
  {{- $namespace := get . "namespace" }}
  {{- if $namespace }}
    {{- $namespace = $namespace | trimPrefix "/" | trimSuffix "/" }}
  {{- end }}
  {{- $repository := get . "repository" }}
  {{- $tag := get . "tag" }}
  {{- $digest := get . "digest" }}

  {{- /* 2. 必选字段校验 */ -}}
  {{- if empty $repository -}}
    {{- fail (printf "workloads.Container.imageRef: imageRef.repository cannot be empty (required field). Values: '%v'" .) -}}
  {{- end -}}

  {{- /* 3. 处理 tag 和 digest 的默认值（二者至少一个非空） */ -}}
  {{- if and (empty $tag) (empty $digest) -}}
    {{- $tag = "latest" -}}
  {{- end -}}

  {{- /* 4. 补全 digest 的 sha256 前缀 */ -}}
  {{- if and $digest (not (hasPrefix "sha256" $digest)) -}}
    {{- $digest = printf "sha256:%s" $digest -}}
  {{- end -}}

  {{- /* 5. 拼接镜像地址：registry/namespace/repository:tag@digest */ -}}
  {{- $imagePrefix := join "/" (list $registry $namespace $repository | compact) }}
  {{- $imageWithTag := join ":" (list $imagePrefix $tag | compact) }}
  {{- $fullImage := join "@" (list $imageWithTag $digest | compact) }}

  {{- $fullImage }}
{{- end }}
