{{- /*
  渲染 Kubernetes EnvFromSource 字段片段。

  行为 (按 K8s API 规范字段顺序):
    - configMapRef (ConfigMapEnvSource, 与 secretRef 互斥): 值为 map 时原样透传；为 string 时按 name、optional 位次组装；委托 definitions.configMapEnvSource。
    - prefix (string, 可选): 非空时原样输出，不校验内容。
    - secretRef (SecretEnvSource, 与 configMapRef 互斥): 值为 map 时原样透传；为 string 时按 name、optional 位次组装；委托 definitions.secretEnvSource。

  边界:
    - 只输出当前出现的引用字段与可选 prefix，不包含 envFrom 父键或数组包装；父键与数组由调用方负责。
    - configMapRef 与 secretRef 必须恰好出现一个；两个并存时中断并列出实际字段名，都未出现时中断并指明必须提供其中一个。
    - 引用值为 map 时不做校验、补全或改写；为 string 时以空白或逗号切分，首段为 name、次段为 optional，多余段忽略，无有效段时不输出该字段。
    - 引用值既不是 map 也不是 string 时中断，失败消息包含字段名。
    - prefix 缺失、为 null 或为空字符串时不输出该键；不是 string 时由 base.string.normalize 中断。
    - definitions.configMapEnvSource 与 definitions.secretEnvSource 当前未实现，其可用性由后续变更提供。

  入参: 上下文 map，即 EnvFromSource 形状，可包含以下字段:
    - configMapRef (ConfigMapEnvSource, 与 secretRef 互斥)
    - prefix       (string, 可选)
    - secretRef    (SecretEnvSource, 与 configMapRef 互斥)

  返回值: 可嵌入 envFrom 数组项的 YAML 字段片段；无有效内容时为空内容。

  示例:
    {{- include "definitions.envFromSource" (dict "configMapRef" (dict "name" "cfg")) }}
    {{- include "definitions.envFromSource" (dict "secretRef" "db-creds true" "prefix" "/db") }}
*/ -}}
{{- define "definitions.envFromSource" -}}
  {{- $const := include "base.env" "" | fromYaml }}

  {{- /* configMapRef 与 secretRef（互斥关联字段，必须恰好出现一个）: 先完成互斥校验，再由同一布尔量派生字段名与子模板名。 */ -}}
  {{- $hasConfigMapRef := hasKey . "configMapRef" }}
  {{- $hasSecretRef := hasKey . "secretRef" }}
  {{- if eq $hasConfigMapRef $hasSecretRef }}
    {{- $_present := list }}
    {{- if $hasConfigMapRef }}
      {{- $_present = mustAppend $_present "configMapRef" }}
    {{- end }}
    {{- if $hasSecretRef }}
      {{- $_present = mustAppend $_present "secretRef" }}
    {{- end }}
    {{- fail (printf "[definitions.envFromSource] fields: exactly one of 'configMapRef' or 'secretRef' is required, got '%v'" (join ", " $_present)) }}
  {{- end }}
  {{- $refKey := ternary "configMapRef" "secretRef" $hasConfigMapRef }}
  {{- $refDefine := ternary "definitions.configMapEnvSource" "definitions.secretEnvSource" $hasConfigMapRef }}
  {{- $_raw := get . $refKey }}

  {{- /* 引用值归一: string 按 name、optional 位次组装；map 原样透传；其余类型中断。 */ -}}
  {{- $ref := dict }}
  {{- $hasRef := true }}
  {{- if kindIs "string" $_raw }}
    {{- $_parts := mustWithout (mustRegexSplit $const.SPLIT.SPACE_COMMA (trim $_raw) -1) "" }}
    {{- $hasRef = gt (len $_parts) 0 }}
    {{- if $hasRef }}
      {{- $_ := set $ref "name" (index $_parts 0) }}
      {{- if ge (len $_parts) 2 }}
        {{- $_ := set $ref "optional" (index $_parts 1) }}
      {{- end }}
    {{- end }}

  {{- else if kindIs "map" $_raw }}
    {{- $ref = $_raw }}

  {{- else }}
    {{- fail (printf "[definitions.envFromSource] %s: must be object or string, got '%s'" $refKey (kindOf $_raw)) }}
  {{- end }}

  {{- /* 委托引用子模板: 结果非法 YAML 时中断，非空时以 base.field 与 base.map 渲染为片段。 */ -}}
  {{- $refFragment := "" }}
  {{- if $hasRef }}
    {{- $_rendered := include $refDefine $ref | fromYaml }}
    {{- if eq (include "base.isFromYamlError" $_rendered) "true" }}
      {{- fail (printf "[definitions.envFromSource] %s: invalid YAML output from %s" $refKey $refDefine) }}
    {{- end }}
    {{- if $_rendered }}
      {{- $refFragment = include "base.field" (list $refKey $_rendered "base.map") }}
    {{- end }}
  {{- end }}

  {{- /* prefix（string, 可选）: 经 base.get 与 YAML 标量解码取值，非空时原样以带引号标量输出为片段。 */ -}}
  {{- $prefixFragment := "" }}
  {{- $_prefixRaw := include "base.get" (list . "prefix") }}
  {{- if $_prefixRaw }}
    {{- $prefix := include "base.string.normalize" $_prefixRaw | trim }}
    {{- if $prefix }}
      {{- $prefixFragment = include "base.field" (list "prefix" $prefix "quote") }}
    {{- end }}
  {{- end }}

  {{- /* 按官方字段顺序输出: configMapRef 在 prefix 之前，secretRef 在 prefix 之后。 */ -}}
  {{- if $hasConfigMapRef }}
    {{- $refFragment }}{{ $prefixFragment }}
  {{- else }}
    {{- $prefixFragment }}{{ $refFragment }}
  {{- end }}
{{- end }}
