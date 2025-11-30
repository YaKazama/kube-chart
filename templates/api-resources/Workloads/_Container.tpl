{{- define "workloads.Container" -}}
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
    {{- $env = append $env (include "definitions.EnvVar" . | fromYaml) }}
  {{- end }}
  {{- $env = $env | mustUniq | mustCompact }}
  {{- if $env }}
    {{- include "base.field" (list "env" $env "base.slice") }}
  {{- end }}

  {{- /* envFrom array */ -}}
  {{- $envFromVal := include "base.getValue" (list . "envFrom") | fromYamlArray }}
  {{- $envFrom := list }}
  {{- range $envFromVal }}
    {{- $envFrom = append $envFrom (include "definitions.EnvFromSource" . | fromYaml) }}
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
      {{- fail "Container: imageRef.repository cannot be empty." }}
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
    {{- fail "Container: image must be exists. need set 'image' or 'imageRef'." }}
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
    {{- $lifecycle := include "definitions.Lifecycle" $lifecycleVal | fromYaml }}
    {{- if $lifecycle }}
      {{- include "base.field" (list "lifecycle" $lifecycle "base.map") }}
    {{- end }}
  {{- end }}

  {{- /* livenessProbe map */ -}}
  {{- $livenessProbeVal := include "base.getValue" (list . "livenessProbe") | fromYaml }}
  {{- if $livenessProbeVal }}
    {{- $_ := set $livenessProbeVal "_type" "liveness" }}
    {{- $livenessProbe := include "definitions.Probe" $livenessProbeVal | fromYaml }}
    {{- if $livenessProbe }}
      {{- include "base.field" (list "livenessProbe" $livenessProbe "base.map") }}
    {{- end }}
  {{- end }}

  {{- /* name string */ -}}
  {{- $name := include "base.getValue" (list . "name") }}
  {{- if (include "base.name" $name) }}
    {{- include "base.field" (list "name" $name) }}
  {{- end }}

  {{- /* ports array */ -}}
  {{- $portsVal := include "base.getValue" (list . "ports") | fromYamlArray }}
  {{- $ports := list }}
  {{- range $portsVal }}
    {{- $ports = append $ports (include "definitions.ContainerPort" . | fromYaml) }}
  {{- end }}
  {{- $ports = $ports | mustUniq | mustCompact }}
  {{- if $ports }}
    {{- include "base.field" (list "ports" $ports "base.slice") }}
  {{- end }}

  {{- /* readinessProbe map */ -}}
  {{- $readinessProbeVal := include "base.getValue" (list . "readinessProbe") | fromYaml }}
  {{- if $readinessProbeVal }}
    {{- $_ := set $readinessProbeVal "_type" "readiness" }}
    {{- $readinessProbe := include "definitions.Probe" $readinessProbeVal | fromYaml }}
    {{- if $readinessProbe }}
      {{- include "base.field" (list "readinessProbe" $readinessProbe "base.map") }}
    {{- end }}
  {{- end }}

  {{- /* resizePolicy array */ -}}
  {{- $resizePolicyVal := include "base.getValue" (list . "resizePolicy") | fromYamlArray }}
  {{- $resizePolicy := list }}
  {{- range $resizePolicyVal }}
    {{- $resizePolicy = append $resizePolicy (include "definitions.ContainerResizePolicy" . | fromYaml) }}
  {{- end }}
  {{- $resizePolicy = $resizePolicy | mustUniq | mustCompact }}
  {{- if $resizePolicy }}
    {{- include "base.field" (list "resizePolicy" $resizePolicy "base.slice") }}
  {{- end }}

  {{- /* resources map */ -}}
  {{- $resourcesVal := include "base.getValue" (list . "resources") | fromYaml }}
  {{- if $resourcesVal }}
    {{- $resources := include "definitions.ResourceRequirements" $resourcesVal | fromYaml }}
    {{- if $resources }}
      {{- include "base.field" (list "resources" $resources "base.map") }}
    {{- end }}
  {{- end }}

  {{- /* restartPolicyRules array */ -}}
  {{- $restartPolicyRulesVal := include "base.getValue" (list . "restartPolicyRules") | fromYamlArray }}
  {{- $restartPolicyRules := list }}
  {{- range $restartPolicyRulesVal }}
    {{- $restartPolicyRules = append $restartPolicyRules (include "definitions.ContainerRestartRule" . | fromYaml) }}
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
    {{- /* 将 os 的值传递下去 */ -}}
    {{- $osVal := include "base.getValue" (list . "os") }}
    {{- $_ := set $securityContextVal "os" $osVal }}
    {{- $securityContext := include "definitions.SecurityContext" $securityContextVal | fromYaml }}
    {{- if $securityContext }}
      {{- include "base.field" (list "securityContext" $securityContext "base.map") }}
    {{- end }}
  {{- end }}

  {{- /* startupProbe map */ -}}
  {{- $startupProbeVal := include "base.getValue" (list . "startupProbe") | fromYaml }}
  {{- if $startupProbeVal }}
    {{- $_ := set $startupProbeVal "_type" "startup" }}
    {{- $startupProbe := include "definitions.Probe" $startupProbeVal | fromYaml }}
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
    {{- include "base.field" (list "terminationMessagePath" $terminationMessagePath) }}
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
    {{- $volumeDevices = append $volumeDevices (include "definitions.VolumeDevice" . | fromYaml) }}
  {{- end }}
  {{- $volumeDevices = $volumeDevices | mustUniq | mustCompact }}
  {{- if $volumeDevices }}
    {{- include "base.field" (list "volumeDevices" $volumeDevices "base.slice") }}
  {{- end }}

  {{- /* volumeMounts array */ -}}
  {{- $volumeMountsVal := include "base.getValue" (list . "volumeMounts") | fromYamlArray }}
  {{- $volumeMounts := list }}
  {{- range $volumeMountsVal }}
    {{- $volumeMounts = append $volumeMounts (include "definitions.VolumeMount" . | fromYaml) }}
  {{- end }}
  {{- $volumeMounts = $volumeMounts | mustUniq | mustCompact }}
  {{- if $volumeMounts }}
    {{- include "base.field" (list "volumeMounts" $volumeMounts "base.slice") }}
  {{- end }}

  {{- /* workingDir string */ -}}
  {{- $workingDir := include "base.getValue" (list . "workingDir") }}
  {{- if $workingDir }}
    {{- include "base.field" (list "workingDir" $workingDir) }}
  {{- end }}
{{- end }}
