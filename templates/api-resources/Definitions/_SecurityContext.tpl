{{- /*
  渲染 Kubernetes SecurityContext 字段片段。

  行为 (按 K8s API 规范字段顺序):
    - allowPrivilegeEscalation (boolean, 可选): 去引号后非空即生效，显式 false 有效；类型门禁与输出委托 base.bool。
    - appArmorProfile (AppArmorProfile, 可选): 非空 map 时委托 definitions.appArmorProfile 渲染。
    - capabilities (Capabilities, 可选): 非空 map 时委托 definitions.capabilities 渲染；该模板当前不存在，非空输入中断。
    - privileged (boolean, 可选): 同 allowPrivilegeEscalation。
    - procMount (string, 可选): 归一后非空时以 Default、Unmasked 枚举校验并输出。
    - readOnlyRootFilesystem (boolean, 可选): 同 allowPrivilegeEscalation。
    - runAsGroup (integer, 可选): 非空时按整数输出，显式 0 有效。
    - runAsNonRoot (boolean, 可选): 同 allowPrivilegeEscalation。
    - runAsUser (integer, 可选): 同 runAsGroup。
    - seLinuxOptions (SELinuxOptions, 可选): 非空 map 时委托 definitions.seLinuxOptions 渲染。
    - seccompProfile (SeccompProfile, 可选): 非空 map 时委托 definitions.seccompProfile 渲染。
    - windowsOptions (WindowsSecurityContextOptions, 可选): 非空 map 时委托 definitions.windowsSecurityContextOptions 渲染。

  边界:
    - 只输出当前层字段，不输出 os、父级 securityContext 键、apiVersion 或 kind；无有效内容时输出空内容。
    - os 只作为适用性控制输入：缺省、取不到 name、无法归一化为 string 或不是 linux、windows 时按 linux 处理，比较前统一转小写。
    - runAsNonRoot 同时适用于 linux 与 windows；os=windows 时出现其他字段、按 linux 处理时出现 windowsOptions 均中断。
    - 适用性按键存在性判定：null 视为不存在，空 map、空 array、空字符串与 0 视为存在；校验先于任何字段输出完成。
    - 标量取值统一 trim；boolean 字段的非空原始输出剥离 YAML 引号后交由 base.bool；integer 字段显式 0 有效，空值不按 0 处理。
    - procMount 官方类型为 string，枚举为 Default、Unmasked；boolean、数字等非 string 输入中断。
    - 本模板自身产生的失败消息使用 [definitions.securityContext] 前缀并携带字段名；委托 base.* 与子模板时保留其自身前缀。
    - base.get 默认开启别名识别，因此各字段同级 <字段>Alias 隐式生效；除 os 与上述字段及其同级别名以外的入参字段静默忽略。
    - 委托的 definitions.capabilities 由后续 change 实现，本模板只按名称调用，不创建其 define。

  入参: 上下文 map，由 definitions.container 传入 securityContext 副本并注入同源 os，可包含以下字段:
    - os                          (PodOS, 可选)                        仅用于适用性判定，不参与输出
    - allowPrivilegeEscalation    (boolean, 可选)
    - appArmorProfile             (AppArmorProfile, 可选)
    - capabilities                (Capabilities, 可选)
    - privileged                  (boolean, 可选)
    - procMount                   (string, 可选)
    - readOnlyRootFilesystem      (boolean, 可选)
    - runAsGroup                  (integer, 可选)
    - runAsNonRoot                (boolean, 可选)
    - runAsUser                   (integer, 可选)
    - seLinuxOptions              (SELinuxOptions, 可选)
    - seccompProfile              (SeccompProfile, 可选)
    - windowsOptions              (WindowsSecurityContextOptions, 可选)

  返回值: 可嵌入 securityContext 下的 SecurityContext YAML 字段片段；无有效内容时为空内容。

  示例:
    {{- include "definitions.securityContext" (dict "os" (dict "name" "linux") "privileged" false) }}
*/ -}}
{{- define "definitions.securityContext" -}}
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
  {{- $linuxOnlyFields := list "allowPrivilegeEscalation" "appArmorProfile" "capabilities" "privileged" "procMount" "readOnlyRootFilesystem" "runAsGroup" "runAsUser" "seLinuxOptions" "seccompProfile" }}
  {{- $forbiddenFields := ternary $linuxOnlyFields (list "windowsOptions") (eq $os "windows") }}
  {{- range $_field := $forbiddenFields }}
    {{- $_aliasKey := printf "%sAlias" $_field }}
    {{- if or (and (hasKey $ $_field) (ne (kindOf (get $ $_field)) "invalid")) (and (hasKey $ $_aliasKey) (ne (kindOf (get $ $_aliasKey)) "invalid")) }}
      {{- fail (printf "[definitions.securityContext] %s: cannot be set when os is %s" $_field $os) }}
    {{- end }}
  {{- end }}

  {{- /* allowPrivilegeEscalation（boolean, 可选）: 去引号后非空即生效，显式 false 有效；类型门禁与输出委托 base.bool。 */ -}}
  {{- $_allowPrivilegeEscalationRaw := include "base.get" (list . "allowPrivilegeEscalation") | trim }}
  {{- if $_allowPrivilegeEscalationRaw }}
    {{- include "base.field" (list "allowPrivilegeEscalation" (mustRegexReplaceAll $const.SYS.YAML_QUOTED $_allowPrivilegeEscalationRaw "$1" | trim) "base.bool") }}
  {{- end }}

  {{- /* appArmorProfile（AppArmorProfile, 可选）: 原始输出非空时委托 definitions.appArmorProfile。 */ -}}
  {{- include "definitions.securityContext.struct" (dict "key" "appArmorProfile" "define" "definitions.appArmorProfile" "raw" (include "base.get" (list . "appArmorProfile"))) }}

  {{- /* capabilities（Capabilities, 可选）: 原始输出非空时委托 definitions.capabilities；该模板当前不存在。 */ -}}
  {{- include "definitions.securityContext.struct" (dict "key" "capabilities" "define" "definitions.capabilities" "raw" (include "base.get" (list . "capabilities"))) }}

  {{- /* privileged（boolean, 可选）: 同 allowPrivilegeEscalation。 */ -}}
  {{- $_privilegedRaw := include "base.get" (list . "privileged") | trim }}
  {{- if $_privilegedRaw }}
    {{- include "base.field" (list "privileged" (mustRegexReplaceAll $const.SYS.YAML_QUOTED $_privilegedRaw "$1" | trim) "base.bool") }}
  {{- end }}

  {{- /* procMount（string, 可选）: 归一后非空时按 Default、Unmasked 枚举校验并输出。 */ -}}
  {{- $procMount := include "base.string.normalize" (include "base.get" (list . "procMount")) | trim }}
  {{- if $procMount }}
    {{- include "base.field" (list "procMount" $procMount "base.string" (list "Default" "Unmasked")) }}
  {{- end }}

  {{- /* readOnlyRootFilesystem（boolean, 可选）: 同 allowPrivilegeEscalation。 */ -}}
  {{- $_readOnlyRootFilesystemRaw := include "base.get" (list . "readOnlyRootFilesystem") | trim }}
  {{- if $_readOnlyRootFilesystemRaw }}
    {{- include "base.field" (list "readOnlyRootFilesystem" (mustRegexReplaceAll $const.SYS.YAML_QUOTED $_readOnlyRootFilesystemRaw "$1" | trim) "base.bool") }}
  {{- end }}

  {{- /* runAsGroup（integer, 可选）: 非空即生效，显式 0 有效；类型门禁与输出委托 base.int。 */ -}}
  {{- $_runAsGroupRaw := include "base.get" (list . "runAsGroup") | trim }}
  {{- if $_runAsGroupRaw }}
    {{- include "base.field" (list "runAsGroup" $_runAsGroupRaw "base.int") }}
  {{- end }}

  {{- /* runAsNonRoot（boolean, 可选）: 同 allowPrivilegeEscalation；linux 与 windows 均适用。 */ -}}
  {{- $_runAsNonRootRaw := include "base.get" (list . "runAsNonRoot") | trim }}
  {{- if $_runAsNonRootRaw }}
    {{- include "base.field" (list "runAsNonRoot" (mustRegexReplaceAll $const.SYS.YAML_QUOTED $_runAsNonRootRaw "$1" | trim) "base.bool") }}
  {{- end }}

  {{- /* runAsUser（integer, 可选）: 同 runAsGroup。 */ -}}
  {{- $_runAsUserRaw := include "base.get" (list . "runAsUser") | trim }}
  {{- if $_runAsUserRaw }}
    {{- include "base.field" (list "runAsUser" $_runAsUserRaw "base.int") }}
  {{- end }}

  {{- /* seLinuxOptions（SELinuxOptions, 可选）: 原始输出非空时委托 definitions.seLinuxOptions。 */ -}}
  {{- include "definitions.securityContext.struct" (dict "key" "seLinuxOptions" "define" "definitions.seLinuxOptions" "raw" (include "base.get" (list . "seLinuxOptions"))) }}

  {{- /* seccompProfile（SeccompProfile, 可选）: 原始输出非空时委托 definitions.seccompProfile。 */ -}}
  {{- include "definitions.securityContext.struct" (dict "key" "seccompProfile" "define" "definitions.seccompProfile" "raw" (include "base.get" (list . "seccompProfile"))) }}

  {{- /* windowsOptions（WindowsSecurityContextOptions, 可选）: 原始输出非空时委托 definitions.windowsSecurityContextOptions。 */ -}}
  {{- include "definitions.securityContext.struct" (dict "key" "windowsOptions" "define" "definitions.windowsSecurityContextOptions" "raw" (include "base.get" (list . "windowsOptions"))) }}
{{- end }}


{{- /*
  渲染单个委托结构字段。

  行为:
    - 原始输出为空时跳过；非空时按 YAML 解析，解析错误中断。
    - 空 map 不调用子模板，也不输出字段。
    - 以解析结果作为上下文调用指定子模板，回收非空结果；结果不可解析时中断，非空时以 base.field 与 base.map 输出。

  边界:
    - 只处理单个字段，不负责取值、别名识别与 os 适用性判定。
    - 失败消息使用 [definitions.securityContext] 前缀并携带字段名，子模板失败消息保留其自身前缀。

  入参: 上下文 map，恒含以下字段:
    - key    (string, 必填) 输出字段名
    - define (string, 必填) 子模板名
    - raw    (string, 可选) base.get 返回的原始 YAML 字符串

  返回值: 可嵌入 SecurityContext 的单字段 YAML 片段；无有效内容时为空内容。

  示例:
    {{- include "definitions.securityContext.struct" (dict "key" "seLinuxOptions" "define" "definitions.seLinuxOptions" "raw" (include "base.get" (list . "seLinuxOptions"))) }}
*/ -}}
{{- define "definitions.securityContext.struct" -}}
  {{- $key := .key }}
  {{- $define := .define }}
  {{- $_raw := .raw | trim }}

  {{- if $_raw }}
    {{- $_parsed := $_raw | fromYaml }}
    {{- if eq (include "base.isFromYamlError" $_parsed) "true" }}
      {{- fail (printf "[definitions.securityContext] %s: must be map type" $key) }}
    {{- end }}

    {{- /* 空 map 表示该结构未设置，不调用子模板也不输出字段。 */ -}}
    {{- if $_parsed }}
      {{- $_rendered := include $define $_parsed | fromYaml }}
      {{- if eq (include "base.isFromYamlError" $_rendered) "true" }}
        {{- fail (printf "[definitions.securityContext] %s: invalid YAML output from %s" $key $define) }}
      {{- end }}
      {{- if $_rendered }}
        {{- include "base.field" (list $key $_rendered "base.map") }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}
