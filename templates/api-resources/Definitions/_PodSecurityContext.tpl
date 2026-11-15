{{- /*
  渲染 Kubernetes PodSecurityContext 字段片段。

  行为 (按 K8s API 规范字段顺序):
    - appArmorProfile (AppArmorProfile, 可选): 非空 map 时委托 definitions.appArmorProfile 渲染。
    - fsGroup (integer, 可选): 非空时按整数输出，显式 0 有效。
    - fsGroupChangePolicy (string, 可选): 非空时以 Always、OnRootMismatch 枚举校验后输出。
    - runAsGroup (integer, 可选): 同 fsGroup。
    - runAsNonRoot (boolean, 可选): 非空时按布尔输出，显式 false 有效。
    - runAsUser (integer, 可选): 同 fsGroup。
    - seLinuxChangePolicy (string, 可选): 非空时以 MountOption、Recursive 枚举校验后输出。
    - seLinuxOptions (SELinuxOptions, 可选): 非空 map 时委托 definitions.seLinuxOptions 渲染。
    - seccompProfile (SeccompProfile, 可选): 非空 map 时委托 definitions.seccompProfile 渲染。
    - supplementalGroups (integer array, 可选): 去空、去重后非空时输出，0 有效。
    - supplementalGroupsPolicy (string, 可选): 非空时以 Merge、Strict 枚举校验后输出。
    - sysctls (Sysctl array, 可选): 逐条清洗、去重后委托 definitions.sysctl 并回收非空结果。
    - windowsOptions (WindowsSecurityContextOptions, 可选): 非空 map 时委托 definitions.windowsSecurityContextOptions 渲染。

  边界:
    - 只输出当前层字段，不输出 os、父级 securityContext 键、apiVersion 或 kind；无有效内容时输出空内容。
    - os 只作为适用性控制输入：缺省、取不到 name、无法归一化为 string 或不是 linux、windows 时按 linux 处理，比较前统一转小写。
    - runAsNonRoot 同时适用于 linux 与 windows；os=windows 时出现其他字段、按 linux 处理时出现 windowsOptions 均中断。
    - 适用性按键存在性判定：null 视为不存在，空 map、空 array、空字符串与 0 视为存在；校验先于任何字段输出完成。
    - 本模板自身产生的失败消息使用 [definitions.podSecurityContext] 前缀并携带字段名；委托 base.* 与子模板时保留其自身前缀。
    - base.get 默认开启别名识别，因此各字段同级 <字段>Alias 隐式生效；除 os 与上层字段及其同级别名以外的入参字段静默忽略。
    - 委托的 5 个子模板由后续 change 实现，本模板只按名称调用，不创建其 define。

  入参: 上下文 map，由 core.podSpec 传入 securityContext 副本并注入同源 os，可包含以下字段:
    - os                          (PodOS, 可选)                        仅用于适用性判定，不参与输出
    - appArmorProfile             (AppArmorProfile, 可选)
    - fsGroup                     (integer, 可选)
    - fsGroupChangePolicy         (string, 可选)
    - runAsGroup                  (integer, 可选)
    - runAsNonRoot                (boolean, 可选)
    - runAsUser                   (integer, 可选)
    - seLinuxChangePolicy         (string, 可选)
    - seLinuxOptions              (SELinuxOptions, 可选)
    - seccompProfile              (SeccompProfile, 可选)
    - supplementalGroups          (integer array, 可选)
    - supplementalGroupsPolicy    (string, 可选)
    - sysctls                     (Sysctl array, 可选)
    - windowsOptions              (WindowsSecurityContextOptions, 可选)

  返回值: 可嵌入 securityContext 下的 PodSecurityContext YAML 字段片段；无有效内容时为空内容。

  示例:
    {{- include "definitions.podSecurityContext" (dict "os" (dict "name" "linux") "fsGroup" 1000) }}
*/ -}}
{{- define "definitions.podSecurityContext" -}}
  {{- $const := include "base.env" "" | fromYaml }}

  {{- /* os（PodOS, 可选）: 只读取 os.name，去引号并转小写；等于 windows 时为 windows，其余全部按 linux 处理。 */ -}}
  {{- $os := "linux" }}
  {{- $_osNameRaw := include "base.get" (list . "os.name") | trim }}
  {{- if $_osNameRaw }}
    {{- if eq "windows" (lower (mustRegexReplaceAll $const.SYS.YAML_QUOTED $_osNameRaw "$1" | trim)) }}
      {{- $os = "windows" }}
    {{- end }}
  {{- end }}

  {{- /* 适用性前置校验: 按 os 选出禁止字段，规范键或同级别名非 null 即中断，全部校验先于字段输出完成。 */ -}}
  {{- $linuxOnlyFields := list "appArmorProfile" "fsGroup" "fsGroupChangePolicy" "runAsGroup" "runAsUser" "seLinuxChangePolicy" "seLinuxOptions" "seccompProfile" "supplementalGroups" "supplementalGroupsPolicy" "sysctls" }}
  {{- $forbiddenFields := ternary $linuxOnlyFields (list "windowsOptions") (eq $os "windows") }}
  {{- range $_field := $forbiddenFields }}
    {{- $_aliasKey := printf "%sAlias" $_field }}
    {{- if or (and (hasKey $ $_field) (ne (kindOf (get $ $_field)) "invalid")) (and (hasKey $ $_aliasKey) (ne (kindOf (get $ $_aliasKey)) "invalid")) }}
      {{- fail (printf "[definitions.podSecurityContext] %s: cannot be set when os is %s" $_field $os) }}
    {{- end }}
  {{- end }}

  {{- /* appArmorProfile（AppArmorProfile, 可选）: 原始输出非空时委托 definitions.appArmorProfile。 */ -}}
  {{- include "definitions.podSecurityContext.struct" (dict "key" "appArmorProfile" "define" "definitions.appArmorProfile" "raw" (include "base.get" (list . "appArmorProfile"))) }}

  {{- /* fsGroup（integer, 可选）: 取值非空即生效，显式 0 有效；类型门禁与输出委托 base.int。 */ -}}
  {{- $_fsGroupRaw := include "base.get" (list . "fsGroup") | trim }}
  {{- if $_fsGroupRaw }}
    {{- include "base.field" (list "fsGroup" $_fsGroupRaw "base.int") }}
  {{- end }}

  {{- /* fsGroupChangePolicy（string, 可选）: 归一后非空时按 Always、OnRootMismatch 校验并输出。 */ -}}
  {{- $fsGroupChangePolicy := include "base.string.normalize" (include "base.get" (list . "fsGroupChangePolicy")) | trim }}
  {{- if $fsGroupChangePolicy }}
    {{- include "base.field" (list "fsGroupChangePolicy" $fsGroupChangePolicy "base.string" (list "Always" "OnRootMismatch")) }}
  {{- end }}

  {{- /* runAsGroup（integer, 可选）: 同 fsGroup。 */ -}}
  {{- $_runAsGroupRaw := include "base.get" (list . "runAsGroup") | trim }}
  {{- if $_runAsGroupRaw }}
    {{- include "base.field" (list "runAsGroup" $_runAsGroupRaw "base.int") }}
  {{- end }}

  {{- /* runAsNonRoot（boolean, 可选）: 去引号后非空即生效，显式 false 有效；类型门禁与输出委托 base.bool。 */ -}}
  {{- $_runAsNonRootRaw := include "base.get" (list . "runAsNonRoot") | trim }}
  {{- if $_runAsNonRootRaw }}
    {{- include "base.field" (list "runAsNonRoot" (mustRegexReplaceAll $const.SYS.YAML_QUOTED $_runAsNonRootRaw "$1" | trim) "base.bool") }}
  {{- end }}

  {{- /* runAsUser（integer, 可选）: 同 fsGroup。 */ -}}
  {{- $_runAsUserRaw := include "base.get" (list . "runAsUser") | trim }}
  {{- if $_runAsUserRaw }}
    {{- include "base.field" (list "runAsUser" $_runAsUserRaw "base.int") }}
  {{- end }}

  {{- /* seLinuxChangePolicy（string, 可选）: 归一后非空时按 MountOption、Recursive 校验并输出。 */ -}}
  {{- $seLinuxChangePolicy := include "base.string.normalize" (include "base.get" (list . "seLinuxChangePolicy")) | trim }}
  {{- if $seLinuxChangePolicy }}
    {{- include "base.field" (list "seLinuxChangePolicy" $seLinuxChangePolicy "base.string" (list "MountOption" "Recursive")) }}
  {{- end }}

  {{- /* seLinuxOptions（SELinuxOptions, 可选）: 原始输出非空时委托 definitions.seLinuxOptions。 */ -}}
  {{- include "definitions.podSecurityContext.struct" (dict "key" "seLinuxOptions" "define" "definitions.seLinuxOptions" "raw" (include "base.get" (list . "seLinuxOptions"))) }}

  {{- /* seccompProfile（SeccompProfile, 可选）: 原始输出非空时委托 definitions.seccompProfile。 */ -}}
  {{- include "definitions.podSecurityContext.struct" (dict "key" "seccompProfile" "define" "definitions.seccompProfile" "raw" (include "base.get" (list . "seccompProfile"))) }}

  {{- /* supplementalGroups（integer array, 可选）: 移除 null 与空字符串、按 base.int 归一为整数后去重，保留显式 0。 */ -}}
  {{- $supplementalGroups := list }}
  {{- $_supplementalGroupsRaw := include "base.get" (list . "supplementalGroups") | trim }}
  {{- if $_supplementalGroupsRaw }}
    {{- $_supplementalGroups := fromYamlArray $_supplementalGroupsRaw }}
    {{- if eq (include "base.isFromYamlArrayError" $_supplementalGroups) "true" }}
      {{- fail "[definitions.podSecurityContext] supplementalGroups: must be array type" }}
    {{- end }}
    {{- range $_item := $_supplementalGroups }}
      {{- if or (kindIs "invalid" $_item) (and (kindIs "string" $_item) (eq (trim $_item) "")) }}
        {{- continue }}
      {{- end }}
      {{- $supplementalGroups = mustAppend $supplementalGroups (atoi (include "base.int" $_item)) }}
    {{- end }}
    {{- $supplementalGroups = mustUniq $supplementalGroups }}
  {{- end }}
  {{- if $supplementalGroups }}
    {{- include "base.field" (list "supplementalGroups" $supplementalGroups "base.slice") }}
  {{- end }}

  {{- /* supplementalGroupsPolicy（string, 可选）: 归一后非空时按 Merge、Strict 校验并输出。 */ -}}
  {{- $supplementalGroupsPolicy := include "base.string.normalize" (include "base.get" (list . "supplementalGroupsPolicy")) | trim }}
  {{- if $supplementalGroupsPolicy }}
    {{- include "base.field" (list "supplementalGroupsPolicy" $supplementalGroupsPolicy "base.string" (list "Merge" "Strict")) }}
  {{- end }}

  {{- /* sysctls（Sysctl array, 可选）: 逐条只取 name 与 value 并归一为 string，去空去重后委托 definitions.sysctl。 */ -}}
  {{- $_sysctlsRaw := include "base.get" (list . "sysctls") | trim }}
  {{- if $_sysctlsRaw }}
    {{- $_sysctls := fromYamlArray $_sysctlsRaw }}
    {{- if eq (include "base.isFromYamlArrayError" $_sysctls) "true" }}
      {{- fail "[definitions.podSecurityContext] sysctls: must be array type" }}
    {{- end }}

    {{- $sysctls := list }}
    {{- range $index, $_item := $_sysctls }}
      {{- if not (kindIs "map" $_item) }}
        {{- fail (printf "[definitions.podSecurityContext] sysctls[%d]: must be map type, got '%s'" $index (kindOf $_item)) }}
      {{- end }}

      {{- $sysctl := dict }}
      {{- range $_name := list "name" "value" }}
        {{- $_value := get $_item $_name }}
        {{- if kindIs "invalid" $_value }}
          {{- $_value = "" }}
        {{- else if or (kindIs "map" $_value) (kindIs "slice" $_value) }}
          {{- fail (printf "[definitions.podSecurityContext] sysctls[%d].%s: must be string type, got '%s'" $index $_name (kindOf $_value)) }}
        {{- else }}
          {{- $_value = trim (toString $_value) }}
        {{- end }}
        {{- $_ := set $sysctl $_name $_value }}
      {{- end }}

      {{- /* name 与 value 均非空才保留；投影后的条目按完整内容去重，同名不同值因 value 不同而保留。 */ -}}
      {{- if and $sysctl.name $sysctl.value }}
        {{- $sysctls = mustAppend $sysctls $sysctl }}
      {{- end }}
    {{- end }}
    {{- $sysctls = mustUniq $sysctls }}

    {{- $sysctlsRendered := list }}
    {{- range $_item := $sysctls }}
      {{- $_rendered := include "definitions.sysctl" $_item | fromYaml }}
      {{- if eq (include "base.isFromYamlError" $_rendered) "true" }}
        {{- fail "[definitions.podSecurityContext] sysctls: definitions.sysctl returned invalid YAML" }}
      {{- end }}
      {{- if $_rendered }}
        {{- $sysctlsRendered = mustAppend $sysctlsRendered $_rendered }}
      {{- end }}
    {{- end }}

    {{- if $sysctlsRendered }}
      {{- include "base.field" (list "sysctls" $sysctlsRendered "base.slice") }}
    {{- end }}
  {{- end }}

  {{- /* windowsOptions（WindowsSecurityContextOptions, 可选）: 原始输出非空时委托 definitions.windowsSecurityContextOptions。 */ -}}
  {{- include "definitions.podSecurityContext.struct" (dict "key" "windowsOptions" "define" "definitions.windowsSecurityContextOptions" "raw" (include "base.get" (list . "windowsOptions"))) }}
{{- end }}


{{- /*
  渲染单个委托结构字段。

  行为:
    - 原始输出为空时跳过；非空时按 YAML 解析，解析错误中断。
    - 解析结果不是 map 时中断；空 map 不调用子模板，也不输出字段。
    - 以解析结果作为上下文调用指定子模板，回收非空结果；结果不可解析时中断，非空时以 base.field 与 base.map 输出。

  边界:
    - 只处理单个字段，不负责取值、别名识别与 os 适用性判定。
    - 失败消息使用 [definitions.podSecurityContext] 前缀并携带字段名，子模板失败消息保留其自身前缀。

  入参: 上下文 map，恒含以下字段:
    - key    (string, 必填) 输出字段名
    - define (string, 必填) 子模板名
    - raw    (string, 可选) base.get 返回的原始 YAML 字符串

  返回值: 可嵌入 PodSecurityContext 的单字段 YAML 片段；无有效内容时为空内容。

  示例:
    {{- include "definitions.podSecurityContext.struct" (dict "key" "seLinuxOptions" "define" "definitions.seLinuxOptions" "raw" (include "base.get" (list . "seLinuxOptions"))) }}
*/ -}}
{{- define "definitions.podSecurityContext.struct" -}}
  {{- $key := .key }}
  {{- $define := .define }}
  {{- $_raw := .raw | trim }}

  {{- if $_raw }}
    {{- $_parsed := $_raw | fromYaml }}
    {{- if eq (include "base.isFromYamlError" $_parsed) "true" }}
      {{- fail (printf "[definitions.podSecurityContext] %s: must be map type" $key) }}
    {{- end }}
    {{- if not (kindIs "map" $_parsed) }}
      {{- fail (printf "[definitions.podSecurityContext] %s: must be map type" $key) }}
    {{- end }}

    {{- /* 空 map 表示该结构未设置，不调用子模板也不输出字段。 */ -}}
    {{- if $_parsed }}
      {{- $_rendered := include $define $_parsed | fromYaml }}
      {{- if eq (include "base.isFromYamlError" $_rendered) "true" }}
        {{- fail (printf "[definitions.podSecurityContext] %s: invalid YAML output from %s" $key $define) }}
      {{- end }}
      {{- if $_rendered }}
        {{- include "base.field" (list $key $_rendered "base.map") }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}
