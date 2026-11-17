{{- /*
  渲染 Kubernetes Container 字段片段。

  行为 (按 K8s API 规范字段顺序):
    - args                 (string array, 可选): 非空数组时按数组输出。
    - command              (string array, 可选): 同 args。
    - env                  (EnvVar array, 可选): envFileRefs 有有效结果时优先，逐项委托 definitions.envVar。
    - envFrom              (EnvFromSource array, 可选): envFromFileRefs 有有效结果时优先，逐项委托 definitions.envFromSource。
    - image                (string, 必填): 按 imageFileRefs > imageRefs > image 三级解析，最终为空时中断。
    - imagePullPolicy      (string, 可选): 按 Always、Never、IfNotPresent 枚举校验后以带引号标量输出。
    - lifecycle            (Lifecycle, 可选): 非空 map 时委托 definitions.lifecycle。
    - livenessProbe        (Probe, 可选): 非空 map 时委托 definitions.probe。
    - name                 (string, 必填): 按 DNS_LABEL 校验后以带引号标量输出。
    - ports                (ContainerPort array, 可选): 逐项委托 definitions.containerPort。
    - readinessProbe       (Probe, 可选): 非空 map 时委托 definitions.probe。
    - resizePolicy         (ContainerResizePolicy array, 可选): 逐项委托 definitions.containerResizePolicy。
    - resources            (ResourceRequirements, 可选): resourcesFileRefs 有有效结果时优先，非空 map 时委托 definitions.resourceRequirements。
    - restartPolicy        (string, 可选): 按 Always、OnFailure、Never 枚举校验后以带引号标量输出。
    - restartPolicyRules   (ContainerRestartRule array, 可选): 逐项委托 definitions.containerRestartRule。
    - securityContext      (SecurityContext, 可选): 非空 map 时注入同源 os 后委托 definitions.securityContext。
    - startupProbe         (Probe, 可选): 非空 map 时委托 definitions.probe。
    - stdin                (boolean, 可选): 按布尔输出，显式 false 也输出。
    - stdinOnce            (boolean, 可选): 同 stdin。
    - terminationMessagePath (string, 可选): 非空时以带引号标量输出。
    - terminationMessagePolicy (string, 可选): 按 File、FallbackToLogsOnError 枚举校验后以带引号标量输出。
    - tty                  (boolean, 可选): 同 stdin。
    - volumeDevices        (VolumeDevice array, 可选): 逐项委托 definitions.volumeDevice。
    - volumeMounts         (VolumeMount array, 可选): 逐项委托 definitions.volumeMount。
    - workingDir           (string, 可选): 非空时以带引号标量输出。

  引用字段优先级:
    - imageFileRefs、envFileRefs、envFromFileRefs、resourcesFileRefs 为 slice，imageRefs 为 map。
    - 同类 *FileRefs 有有效结果时取代对应内联字段，无有效结果时回退内联字段。
    - imageFileRefs 内容解析为 map 时按 imageRefs 规则拼接，否则按标量直接使用。

  边界:
    - 只输出当前层字段，不输出 containers 父键、apiVersion 或 kind；name 与 image 必填，模板恒有输出。
    - 上下文为展开后的单个容器字段 map，与 os、Files、Values、Context 同层，不要求 containers 包装键。
    - os 只透传给 definitions.securityContext，本模板不解析其内容。
    - 字符串字段缺失、为 null、为空字符串或只含空白时按未提供处理，跳过输出。
    - 字符串字段不是 string 时由 base.string.normalize 中断，不做类型归一化。
    - 枚举比较大小写敏感，未命中时由 base.field 中断并给出合法范围。
    - *FileRefs 的 filePath 必填、必须是 Chart 内相对路径且不得逃逸根目录，由 base.fileRefs 中断。
    - 数组字段非 array 或元素非对象时中断；委托结果为空时剔除该项，全部为空时不输出该字段。
    - base.get 默认开启别名识别，因此各字段同级 <字段>Alias 隐式生效；除上述字段及其同级别名以外的入参字段静默忽略，不输出 status。

  入参: 上下文 map，由 core.podSpec 传入容器字段并注入同源 os 与 Files、Values、Context。

  返回值: 可嵌入 containers 或 initContainers 元素下的 Container YAML 字段片段。

  示例:
    {{- include "definitions.container" (dict "name" "app" "image" "nginx:1.27") }}
      // image: "nginx:1.27"
      // name: "app"
*/ -}}
{{- define "definitions.container" -}}
  {{- $const := include "base.env" "" | fromYaml }}

  {{- /* args（string array, 可选）: 非空数组时按数组输出。 */ -}}
  {{- $_argsRaw := include "base.get" (list . "args") | trim }}
  {{- if $_argsRaw }}
    {{- $_args := $_argsRaw | fromYamlArray }}
    {{- if eq (include "base.isFromYamlArrayError" $_args) "true" }}
      {{- fail "[definitions.container] args: must be array type" }}
    {{- end }}
    {{- if $_args }}
      {{- include "base.field" (list "args" $_args "base.slice") }}
    {{- end }}
  {{- end }}

  {{- /* command（string array, 可选）: 非空数组时按数组输出。 */ -}}
  {{- $_commandRaw := include "base.get" (list . "command") | trim }}
  {{- if $_commandRaw }}
    {{- $_command := $_commandRaw | fromYamlArray }}
    {{- if eq (include "base.isFromYamlArrayError" $_command) "true" }}
      {{- fail "[definitions.container] command: must be array type" }}
    {{- end }}
    {{- if $_command }}
      {{- include "base.field" (list "command" $_command "base.slice") }}
    {{- end }}
  {{- end }}

  {{- /* env（EnvVar array, 可选）: envFileRefs 有有效结果时优先，逐项委托 definitions.envVar。 */ -}}
  {{- $_envSource := "" }}
  {{- $_envFileRefsRaw := include "base.get" (list . "envFileRefs") | trim }}
  {{- if $_envFileRefsRaw }}
    {{- $_envSource = include "base.fileRefs" (list . $_envFileRefsRaw) }}
  {{- end }}
  {{- if not $_envSource }}
    {{- $_envSource = include "base.get" (list . "env") | trim }}
  {{- end }}
  {{- include "definitions.container.array" (dict "key" "env" "define" "definitions.envVar" "raw" $_envSource) }}

  {{- /* envFrom（EnvFromSource array, 可选）: envFromFileRefs 有有效结果时优先，逐项委托 definitions.envFromSource。 */ -}}
  {{- $_envFromSource := "" }}
  {{- $_envFromFileRefsRaw := include "base.get" (list . "envFromFileRefs") | trim }}
  {{- if $_envFromFileRefsRaw }}
    {{- $_envFromSource = include "base.fileRefs" (list . $_envFromFileRefsRaw) }}
  {{- end }}
  {{- if not $_envFromSource }}
    {{- $_envFromSource = include "base.get" (list . "envFrom") | trim }}
  {{- end }}
  {{- include "definitions.container.array" (dict "key" "envFrom" "define" "definitions.envFromSource" "raw" $_envFromSource) }}

  {{- /* image（string, 必填）: imageFileRefs 解析结果优先，其次 imageRefs，最后回退 image；最终为空时中断。 */ -}}
  {{- $image := "" }}
  {{- $_imageFileRefsRaw := include "base.get" (list . "imageFileRefs") | trim }}
  {{- if $_imageFileRefsRaw }}
    {{- $_imageFromFile := include "base.fileRefs" (list . $_imageFileRefsRaw) }}
    {{- if $_imageFromFile }}
      {{- $_imageParsed := $_imageFromFile | fromYaml }}
      {{- if eq (include "base.isFromYamlError" $_imageParsed) "true" }}
        {{- $image = include "base.string.normalize" $_imageFromFile | trim }}
      {{- else }}
        {{- $image = include "definitions.container.imageRef" $_imageParsed }}
      {{- end }}
    {{- end }}
  {{- end }}
  {{- if not $image }}
    {{- $_imageRefsRaw := include "base.get" (list . "imageRefs") | trim }}
    {{- if $_imageRefsRaw }}
      {{- $_imageRefsParsed := $_imageRefsRaw | fromYaml }}
      {{- if eq (include "base.isFromYamlError" $_imageRefsParsed) "true" }}
        {{- fail "[definitions.container] imageRefs: must be object type" }}
      {{- end }}
      {{- if $_imageRefsParsed }}
        {{- $image = include "definitions.container.imageRef" $_imageRefsParsed }}
      {{- end }}
    {{- end }}
  {{- end }}
  {{- if not $image }}
    {{- $image = include "base.string.normalize" (include "base.get" (list . "image")) | trim }}
  {{- end }}
  {{- if not $image }}
    {{- fail "[definitions.container] image: required field is missing or empty" }}
  {{- end }}
  {{- include "base.field" (list "image" $image "quote") }}

  {{- /* imagePullPolicy（string, 可选）: 按枚举校验并以带引号标量输出。 */ -}}
  {{- $imagePullPolicy := include "base.string.normalize" (include "base.get" (list . "imagePullPolicy")) | trim }}
  {{- if $imagePullPolicy }}
    {{- include "base.field" (list "imagePullPolicy" $imagePullPolicy "quote" (list "Always" "Never" "IfNotPresent")) }}
  {{- end }}

  {{- /* lifecycle（Lifecycle, 可选）: 非空 map 时委托 definitions.lifecycle。 */ -}}
  {{- include "definitions.container.struct" (dict "key" "lifecycle" "define" "definitions.lifecycle" "raw" (include "base.get" (list . "lifecycle"))) }}

  {{- /* livenessProbe（Probe, 可选）: 非空 map 时委托 definitions.probe。 */ -}}
  {{- include "definitions.container.struct" (dict "key" "livenessProbe" "define" "definitions.probe" "raw" (include "base.get" (list . "livenessProbe"))) }}

  {{- /* name（string, 必填）: 必填取值并按 DNS_LABEL 校验，以带引号标量输出。 */ -}}
  {{- $name := include "base.string.normalize" (include "base.get" (list . "name" "" "" true)) | trim }}
  {{- if not $name }}
    {{- fail "[definitions.container] name: required field is missing or empty" }}
  {{- end }}
  {{- include "base.field" (list "name" (include "base.rfc" (list $name "1123")) "quote") }}

  {{- /* ports（ContainerPort array, 可选）: 逐项委托 definitions.containerPort。 */ -}}
  {{- include "definitions.container.array" (dict "key" "ports" "define" "definitions.containerPort" "raw" (include "base.get" (list . "ports"))) }}

  {{- /* readinessProbe（Probe, 可选）: 非空 map 时委托 definitions.probe。 */ -}}
  {{- include "definitions.container.struct" (dict "key" "readinessProbe" "define" "definitions.probe" "raw" (include "base.get" (list . "readinessProbe"))) }}

  {{- /* resizePolicy（ContainerResizePolicy array, 可选）: 逐项委托 definitions.containerResizePolicy。 */ -}}
  {{- include "definitions.container.array" (dict "key" "resizePolicy" "define" "definitions.containerResizePolicy" "raw" (include "base.get" (list . "resizePolicy"))) }}

  {{- /* resources（ResourceRequirements, 可选）: resourcesFileRefs 有有效结果时优先，非空 map 时委托 definitions.resourceRequirements。 */ -}}
  {{- $_resourcesSource := "" }}
  {{- $_resourcesFileRefsRaw := include "base.get" (list . "resourcesFileRefs") | trim }}
  {{- if $_resourcesFileRefsRaw }}
    {{- $_resourcesSource = include "base.fileRefs" (list . $_resourcesFileRefsRaw) }}
  {{- end }}
  {{- if not $_resourcesSource }}
    {{- $_resourcesSource = include "base.get" (list . "resources") | trim }}
  {{- end }}
  {{- include "definitions.container.struct" (dict "key" "resources" "define" "definitions.resourceRequirements" "raw" $_resourcesSource) }}

  {{- /* restartPolicy（string, 可选）: 按枚举校验并以带引号标量输出。 */ -}}
  {{- $restartPolicy := include "base.string.normalize" (include "base.get" (list . "restartPolicy")) | trim }}
  {{- if $restartPolicy }}
    {{- include "base.field" (list "restartPolicy" $restartPolicy "quote" (list "Always" "OnFailure" "Never")) }}
  {{- end }}

  {{- /* restartPolicyRules（ContainerRestartRule array, 可选）: 逐项委托 definitions.containerRestartRule。 */ -}}
  {{- include "definitions.container.array" (dict "key" "restartPolicyRules" "define" "definitions.containerRestartRule" "raw" (include "base.get" (list . "restartPolicyRules"))) }}

  {{- /* securityContext（SecurityContext, 可选）: 非空 map 时注入同源 os 后委托 definitions.securityContext。 */ -}}
  {{- $_securityContextRaw := include "base.get" (list . "securityContext") | trim }}
  {{- if $_securityContextRaw }}
    {{- $_securityContextParsed := $_securityContextRaw | fromYaml }}
    {{- if eq (include "base.isFromYamlError" $_securityContextParsed) "true" }}
      {{- fail "[definitions.container] securityContext: must be object type" }}
    {{- end }}
    {{- if $_securityContextParsed }}
      {{- $_securityContext := $_securityContextParsed }}
      {{- if hasKey $ "os" }}
        {{- $_securityContext = mustMerge (dict "os" (get $ "os")) $_securityContextParsed }}
      {{- end }}
      {{- $_rendered := include "definitions.securityContext" $_securityContext | fromYaml }}
      {{- if eq (include "base.isFromYamlError" $_rendered) "true" }}
        {{- fail "[definitions.container] securityContext: definitions.securityContext returned invalid YAML" }}
      {{- end }}
      {{- if $_rendered }}
        {{- include "base.field" (list "securityContext" $_rendered "base.map") }}
      {{- end }}
    {{- end }}
  {{- end }}

  {{- /* startupProbe（Probe, 可选）: 非空 map 时委托 definitions.probe。 */ -}}
  {{- include "definitions.container.struct" (dict "key" "startupProbe" "define" "definitions.probe" "raw" (include "base.get" (list . "startupProbe"))) }}

  {{- /* stdin（boolean, 可选）: 按布尔输出，显式 false 也输出。 */ -}}
  {{- $_stdinRaw := include "base.get" (list . "stdin") | trim }}
  {{- if $_stdinRaw }}
    {{- include "base.field" (list "stdin" (include "base.bool" (mustRegexReplaceAll $const.SYS.YAML_QUOTED $_stdinRaw "$1" | trim)) "base.bool") }}
  {{- end }}

  {{- /* stdinOnce（boolean, 可选）: 按布尔输出，显式 false 也输出。 */ -}}
  {{- $_stdinOnceRaw := include "base.get" (list . "stdinOnce") | trim }}
  {{- if $_stdinOnceRaw }}
    {{- include "base.field" (list "stdinOnce" (include "base.bool" (mustRegexReplaceAll $const.SYS.YAML_QUOTED $_stdinOnceRaw "$1" | trim)) "base.bool") }}
  {{- end }}

  {{- /* terminationMessagePath（string, 可选）: 非空时以带引号标量输出。 */ -}}
  {{- $terminationMessagePath := include "base.string.normalize" (include "base.get" (list . "terminationMessagePath")) | trim }}
  {{- if $terminationMessagePath }}
    {{- include "base.field" (list "terminationMessagePath" $terminationMessagePath "quote") }}
  {{- end }}

  {{- /* terminationMessagePolicy（string, 可选）: 按枚举校验并以带引号标量输出。 */ -}}
  {{- $terminationMessagePolicy := include "base.string.normalize" (include "base.get" (list . "terminationMessagePolicy")) | trim }}
  {{- if $terminationMessagePolicy }}
    {{- include "base.field" (list "terminationMessagePolicy" $terminationMessagePolicy "quote" (list "File" "FallbackToLogsOnError")) }}
  {{- end }}

  {{- /* tty（boolean, 可选）: 按布尔输出，显式 false 也输出。 */ -}}
  {{- $_ttyRaw := include "base.get" (list . "tty") | trim }}
  {{- if $_ttyRaw }}
    {{- include "base.field" (list "tty" (include "base.bool" (mustRegexReplaceAll $const.SYS.YAML_QUOTED $_ttyRaw "$1" | trim)) "base.bool") }}
  {{- end }}

  {{- /* volumeDevices（VolumeDevice array, 可选）: 逐项委托 definitions.volumeDevice。 */ -}}
  {{- include "definitions.container.array" (dict "key" "volumeDevices" "define" "definitions.volumeDevice" "raw" (include "base.get" (list . "volumeDevices"))) }}

  {{- /* volumeMounts（VolumeMount array, 可选）: 逐项委托 definitions.volumeMount。 */ -}}
  {{- include "definitions.container.array" (dict "key" "volumeMounts" "define" "definitions.volumeMount" "raw" (include "base.get" (list . "volumeMounts"))) }}

  {{- /* workingDir（string, 可选）: 非空时以带引号标量输出。 */ -}}
  {{- $workingDir := include "base.string.normalize" (include "base.get" (list . "workingDir")) | trim }}
  {{- if $workingDir }}
    {{- include "base.field" (list "workingDir" $workingDir "quote") }}
  {{- end }}
{{- end }}


{{- /*
  渲染 Container 的数组字段。

  行为:
    - 原始输出为空时跳过；非空时按 YAML 数组解析，解析错误或非数组时中断。
    - 逐项要求为 map，以该项为上下文调用指定子模板，回收非空结果。
    - 子模板返回非法 YAML 时中断；全部结果为空时不输出该字段。

  边界:
    - 只处理单个数组字段，不负责取值来源选择与别名识别；FileRefs 与内联字段的优先级由调用方决定。
    - 失败消息使用 [definitions.container] 前缀并携带字段名，子模板失败消息保留其自身前缀。

  入参: 上下文 map，恒含以下字段:
    - key    (string, 必填) 输出字段名
    - define (string, 必填) 子模板名
    - raw    (string, 可选) 数组字段的原始 YAML 字符串

  返回值: 可嵌入 Container 的单字段 YAML 片段；无有效内容时为空内容。

  示例:
    {{- include "definitions.container.array" (dict "key" "ports" "define" "definitions.containerPort" "raw" (include "base.get" (list . "ports"))) }}
*/ -}}
{{- define "definitions.container.array" -}}
  {{- $key := .key }}
  {{- $define := .define }}
  {{- $_raw := .raw | trim }}

  {{- if $_raw }}
    {{- $_parsed := $_raw | fromYamlArray }}
    {{- if eq (include "base.isFromYamlArrayError" $_parsed) "true" }}
      {{- fail (printf "[definitions.container] %s: must be array type" $key) }}
    {{- end }}

    {{- $items := list }}
    {{- range $_item := $_parsed }}
      {{- if not (kindIs "map" $_item) }}
        {{- fail (printf "[definitions.container] %s: each item must be object type" $key) }}
      {{- end }}
      {{- $_rendered := include $define $_item | fromYaml }}
      {{- if eq (include "base.isFromYamlError" $_rendered) "true" }}
        {{- fail (printf "[definitions.container] %s: invalid YAML output from %s" $key $define) }}
      {{- end }}
      {{- if $_rendered }}
        {{- $items = mustAppend $items $_rendered }}
      {{- end }}
    {{- end }}

    {{- if $items }}
      {{- include "base.field" (list $key $items "base.slice") }}
    {{- end }}
  {{- end }}
{{- end }}


{{- /*
  渲染 Container 的对象字段。

  行为:
    - 原始输出为空时跳过；非空时按 YAML map 解析，解析错误或非 map 时中断。
    - 空 map 视为未设置，不调用子模板也不输出字段。
    - 以解析结果作为上下文调用指定子模板，回收非空结果；结果非法 YAML 时中断，非空时以 base.field 与 base.map 输出。

  边界:
    - 只处理单个对象字段，不负责取值来源选择与别名识别；FileRefs 与内联字段的优先级由调用方决定。
    - 失败消息使用 [definitions.container] 前缀并携带字段名，子模板失败消息保留其自身前缀。

  入参: 上下文 map，恒含以下字段:
    - key    (string, 必填) 输出字段名
    - define (string, 必填) 子模板名
    - raw    (string, 可选) 对象字段的原始 YAML 字符串

  返回值: 可嵌入 Container 的单字段 YAML 片段；无有效内容时为空内容。

  示例:
    {{- include "definitions.container.struct" (dict "key" "lifecycle" "define" "definitions.lifecycle" "raw" (include "base.get" (list . "lifecycle"))) }}
*/ -}}
{{- define "definitions.container.struct" -}}
  {{- $key := .key }}
  {{- $define := .define }}
  {{- $_raw := .raw | trim }}

  {{- if $_raw }}
    {{- $_parsed := $_raw | fromYaml }}
    {{- if eq (include "base.isFromYamlError" $_parsed) "true" }}
      {{- fail (printf "[definitions.container] %s: must be object type" $key) }}
    {{- end }}

    {{- /* 空 map 表示该结构未设置，不调用子模板也不输出字段。 */ -}}
    {{- if $_parsed }}
      {{- $_rendered := include $define $_parsed | fromYaml }}
      {{- if eq (include "base.isFromYamlError" $_rendered) "true" }}
        {{- fail (printf "[definitions.container] %s: invalid YAML output from %s" $key $define) }}
      {{- end }}
      {{- if $_rendered }}
        {{- include "base.field" (list $key $_rendered "base.map") }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}


{{- /*
  按 imageRefs 字段拼接完整镜像引用。

  行为:
    - registry、namespace 去除首尾 `/`；repository 必填，归一后为空时中断。
    - tag 与 digest 均为空时不产生尾缀；digest 非空且 tag 为空时 tag 取 latest。
    - digest 不以 sha256 开头时补全 sha256: 前缀。
    - 按 registry/namespace/repository:tag@digest 的顺序拼接，空段被剔除。

  边界:
    - 只拼接 imageRefs 结构，不读取 imageFileRefs 或 image，也不校验引用整体是否合法。
    - 失败消息使用 [definitions.container] 前缀并携带字段路径。

  入参: 上下文 map，可包含以下字段:
    - registry   (string, 可选) 镜像仓库地址
    - namespace  (string, 可选) 仓库命名空间
    - repository (string, 必填) 镜像仓库名
    - tag        (string, 可选) 镜像标签
    - digest     (string, 可选) 镜像摘要

  返回值: 拼接后的镜像引用字符串。

  示例:
    {{- include "definitions.container.imageRef" (dict "repository" "nginx" "tag" "1.27") }}  // nginx:1.27
    {{- include "definitions.container.imageRef" (dict "registry" "docker.io" "repository" "nginx" "digest" "abc") }}
      // docker.io/nginx:latest@sha256:abc
*/ -}}
{{- define "definitions.container.imageRef" -}}
  {{- $registry := include "base.string.normalize" (include "base.get" (list . "registry")) | trim | trimPrefix "/" | trimSuffix "/" }}
  {{- $namespace := include "base.string.normalize" (include "base.get" (list . "namespace")) | trim | trimPrefix "/" | trimSuffix "/" }}
  {{- $repository := include "base.string.normalize" (include "base.get" (list . "repository")) | trim }}

  {{- /* repository（string, 必填）: 归一后为空时中断，其余字段均可省略。 */ -}}
  {{- if not $repository }}
    {{- fail "[definitions.container] imageRefs.repository: required field is missing or empty" }}
  {{- end }}

  {{- $tag := include "base.string.normalize" (include "base.get" (list . "tag")) | trim }}
  {{- $digest := include "base.string.normalize" (include "base.get" (list . "digest")) | trim }}

  {{- /* tag 与 digest 均空时不产生尾缀；仅有 digest 时补 latest 标签。 */ -}}
  {{- if and $digest (not $tag) }}
    {{- $tag = "latest" }}
  {{- end }}

  {{- /* digest 不以 sha256 开头时补全前缀。 */ -}}
  {{- if and $digest (not (hasPrefix "sha256" $digest)) }}
    {{- $digest = printf "sha256:%s" $digest }}
  {{- end }}

  {{- $image := join "/" (list $registry $namespace $repository | compact) }}
  {{- if $tag }}
    {{- $image = printf "%s:%s" $image $tag }}
  {{- end }}
  {{- if $digest }}
    {{- $image = printf "%s@%s" $image $digest }}
  {{- end }}
  {{- $image }}
{{- end }}
