{{- /*
  渲染 Kubernetes PodSpec 字段片段。

  行为:
    - 按 Kubernetes API 字段顺序输出本模板列出的字段。
    - 统一通过 base.get 取值，兼容同级 <字段名>Alias；多类型输入先归一化后委托 definitions.*。
    - containers 为必填字段；数组委托结果为空、无效 YAML 或非对象时剔除，最终为空则失败。
    - 未列出的 PodSpec 字段忽略；本模板只输出当前层字段，不输出 spec 父键。

  入参: 父级 include 透传的上下文 map，可包含 PodSpec 字段以及 Files、Values、Context。

  返回值: 可嵌入 spec 下的 PodSpec YAML 字段片段。

  示例:
    {{- include "core.podSpec" . }}
*/ -}}
{{- define "core.podSpec" -}}
  {{- $_const := include "base.env" "" | fromYaml }}

  {{- /* os（PodOS, 可选）: 字符串补齐 name，原生对象原样复制，供 PodOS、容器和 PodSecurityContext 复用。 */ -}}
  {{- $os := dict }}
  {{- $_osRaw := include "base.get" (list . "os") | trim }}
  {{- if $_osRaw }}
    {{- $_osParsed := $_osRaw | fromYaml }}
    {{- if eq (include "base.isFromYamlError" $_osParsed) "true" }}
      {{- $_osName := mustRegexReplaceAll $_const.SYS.YAML_QUOTED $_osRaw "$1" | trim }}
      {{- if not $_osName }}
        {{- fail "[core.podSpec] os: must be string or map type" }}
      {{- end }}
      {{- $os = dict "name" $_osName }}
    {{- else if kindIs "map" $_osParsed }}
      {{- $os = mustDeepCopy $_osParsed }}
    {{- else }}
      {{- fail "[core.podSpec] os: must be string or map type" }}
    {{- end }}
  {{- end }}

  {{- /* 布尔字段: 只接受布尔值或 true/false 字面量，归一化结果用于字段生效和互斥判断。 */ -}}
  {{- $bools := dict }}
  {{- range $_name := list "automountServiceAccountToken" "hostIPC" "hostNetwork" "hostPID" "hostUsers" "setHostnameAsFQDN" "shareProcessNamespace" }}
    {{- $_raw := include "base.get" (list $ $_name) | trim }}
    {{- if $_raw }}
      {{- $_value := mustRegexReplaceAll $_const.SYS.YAML_QUOTED $_raw "$1" | trim }}
      {{- if not (or (eq $_value "true") (eq $_value "false")) }}
        {{- fail (printf "[core.podSpec] %s: must be boolean" $_name) }}
      {{- end }}
      {{- $_ := set $bools $_name (eq $_value "true") }}
    {{- end }}
  {{- end }}

  {{- /* hostnameOverride（string, 可选）: 先取值，供互斥约束和字段渲染共同使用。 */ -}}
  {{- $hostnameOverride := mustRegexReplaceAll $_const.SYS.YAML_QUOTED (include "base.get" (list . "hostnameOverride") | trim) "$1" | trim }}

  {{- /* 跨字段互斥约束在任何字段输出前完成。 */ -}}
  {{- if and (get $bools "hostPID") (get $bools "shareProcessNamespace") }}
    {{- fail "[core.podSpec] hostPID: must not be true together with shareProcessNamespace" }}
  {{- end }}
  {{- if and $hostnameOverride (get $bools "hostNetwork") }}
    {{- fail "[core.podSpec] hostnameOverride: conflicting with hostNetwork" }}
  {{- end }}
  {{- if and $hostnameOverride (get $bools "setHostnameAsFQDN") }}
    {{- fail "[core.podSpec] hostnameOverride: conflicting with setHostnameAsFQDN" }}
  {{- end }}

  {{- /* activeDeadlineSeconds（integer, 可选）: 仅正整数生效，0 不输出。 */ -}}
  {{- $activeDeadlineSeconds := mustRegexReplaceAll $_const.SYS.YAML_QUOTED (include "base.get" (list . "activeDeadlineSeconds") | trim) "$1" | trim }}
  {{- if $activeDeadlineSeconds }}
    {{- if not (mustRegexMatch $_const.TYPES.POSITIVE_INT $activeDeadlineSeconds) }}
      {{- fail (printf "[core.podSpec] activeDeadlineSeconds: must be a positive integer, got '%s'" $activeDeadlineSeconds) }}
    {{- end }}
    {{- if gt (atoi $activeDeadlineSeconds) 0 }}
      {{- include "base.field" (list "activeDeadlineSeconds" (include "base.int.positive" $activeDeadlineSeconds) "base.int") }}
    {{- end }}
  {{- end }}

  {{- /* affinity（Affinity, 可选）: 只保留三个官方键，同级字段补缺且 affinity 内值优先。 */ -}}
  {{- $affinity := dict }}
  {{- $_affinityRaw := include "base.get" (list . "affinity") | trim }}
  {{- if $_affinityRaw }}
    {{- $_affinityParsed := $_affinityRaw | fromYaml }}
    {{- if eq (include "base.isFromYamlError" $_affinityParsed) "true" }}
      {{- fail "[core.podSpec] affinity: must be map type" }}
    {{- end }}
    {{- $affinity = mustDeepCopy (pick $_affinityParsed "nodeAffinity" "podAffinity" "podAntiAffinity") }}
  {{- end }}
  {{- $affinitySiblings := dict }}
  {{- range $_key := list "nodeAffinity" "podAffinity" "podAntiAffinity" }}
    {{- $_siblingRaw := include "base.get" (list $ $_key) | trim }}
    {{- if $_siblingRaw }}
      {{- $_siblingParsed := $_siblingRaw | fromYaml }}
      {{- if eq (include "base.isFromYamlError" $_siblingParsed) "true" }}
        {{- fail (printf "[core.podSpec] %s: must be map type" $_key) }}
      {{- end }}
      {{- if $_siblingParsed }}
        {{- $_ := set $affinitySiblings $_key $_siblingParsed }}
      {{- end }}
    {{- end }}
  {{- end }}
  {{- $_ := mustMerge $affinity $affinitySiblings }}
  {{- if $affinity }}
    {{- $_affinityRendered := include "definitions.affinity" $affinity | fromYaml }}
    {{- if and (ne (include "base.isFromYamlError" $_affinityRendered) "true") $_affinityRendered }}
      {{- include "base.field" (list "affinity" $_affinityRendered "base.map") }}
    {{- end }}
  {{- end }}

  {{- /* automountServiceAccountToken（boolean, 可选）: 仅 true 输出。 */ -}}
  {{- if get $bools "automountServiceAccountToken" }}
    {{- include "base.field" (list "automountServiceAccountToken" true "base.bool") }}
  {{- end }}

  {{- /* 容器委托上下文: 固定的 Files、Values、Context 只按存在状态取一次，供 containers 与 initContainers 共用。 */ -}}
  {{- $containerExtras := pick $ "Files" "Values" "Context" }}

  {{- /* containers（Container array, 必填）: map 归一为单元素数组后逐项委托。 */ -}}
  {{- $_containersRaw := include "base.get" (list . "containers") | trim }}
  {{- if not $_containersRaw }}
    {{- fail "[core.podSpec] containers: required field is missing" }}
  {{- end }}
  {{- /* base.get 对数组输出顶层 YAML 序列，需用 fromYamlArray 恢复；失败时再按 map 形态解析为单元素数组。 */ -}}
  {{- $_containers := $_containersRaw | fromYamlArray }}
  {{- if eq (include "base.isFromYamlArrayError" $_containers) "true" }}
    {{- $_containers = $_containersRaw | fromYaml }}
    {{- if eq (include "base.isFromYamlError" $_containers) "true" }}
      {{- fail "[core.podSpec] containers: must be map or array type" }}
    {{- end }}
    {{- $_containers = list $_containers }}
  {{- end }}
  {{- $containers := list }}
  {{- range $_item := $_containers }}
    {{- if not (kindIs "map" $_item) }}
      {{- fail "[core.podSpec] containers: each item must be object type" }}
    {{- end }}
    {{- $_rendered := include "definitions.container" (mustMerge (dict "containers" $_item "os" $os) $containerExtras) | fromYaml }}
    {{- if and (ne (include "base.isFromYamlError" $_rendered) "true") $_rendered }}
      {{- $containers = mustAppend $containers $_rendered }}
    {{- end }}
  {{- end }}
  {{- $containers = mustUniq $containers }}
  {{- if not $containers }}
    {{- fail "[core.podSpec] containers: required field has no valid output" }}
  {{- end }}
  {{- include "base.field" (list "containers" $containers "base.slice") }}

  {{- /* dnsPolicy（string, 可选）: 按 Kubernetes 枚举校验。 */ -}}
  {{- $dnsPolicy := mustRegexReplaceAll $_const.SYS.YAML_QUOTED (include "base.get" (list . "dnsPolicy") | trim) "$1" | trim }}
  {{- if $dnsPolicy }}
    {{- include "base.field" (list "dnsPolicy" $dnsPolicy "base.string" (list "ClusterFirstWithHostNet" "ClusterFirst" "Default" "None")) }}
  {{- end }}

  {{- /* hostAliases（HostAlias array, 可选）: 字符串项按空格/逗号拆分后委托。 */ -}}
  {{- $_hostAliasesRaw := include "base.get" (list . "hostAliases") | trim }}
  {{- if $_hostAliasesRaw }}
    {{- $_hostAliasesArr := $_hostAliasesRaw | fromYamlArray }}
    {{- if eq (include "base.isFromYamlArrayError" $_hostAliasesArr) "true" }}
      {{- fail "[core.podSpec] hostAliases: must be array type" }}
    {{- end }}
    {{- $hostAliases := list }}
    {{- range $_entry := $_hostAliasesArr }}
      {{- $_hostAlias := dict }}
      {{- if kindIs "map" $_entry }}
        {{- $_hostAlias = mustDeepCopy $_entry }}
      {{- else if kindIs "string" $_entry }}
        {{- $_parts := mustWithout (mustRegexSplit $_const.SPLIT.SPACE_COMMA (trim $_entry) -1) "" }}
        {{- if lt (len $_parts) 2 }}
          {{- fail (printf "[core.podSpec] hostAliases: '%s' must contain an IP and hostname" $_entry) }}
        {{- end }}
        {{- $_hostnames := list }}
        {{- range $_hostname := mustRest $_parts }}
          {{- $_hostnames = mustAppend $_hostnames (toString $_hostname) }}
        {{- end }}
        {{- $_hostAlias = dict "ip" (toString (index $_parts 0)) "hostnames" $_hostnames }}
      {{- else }}
        {{- fail "[core.podSpec] hostAliases: each item must be string or object type" }}
      {{- end }}
      {{- $_rendered := include "definitions.hostAlias" $_hostAlias | fromYaml }}
      {{- if and (ne (include "base.isFromYamlError" $_rendered) "true") $_rendered }}
        {{- $hostAliases = mustAppend $hostAliases $_rendered }}
      {{- end }}
    {{- end }}
    {{- $hostAliases = mustUniq $hostAliases }}
    {{- if $hostAliases }}
      {{- include "base.field" (list "hostAliases" $hostAliases "base.slice") }}
    {{- end }}
  {{- end }}

  {{- /* hostIPC（boolean, 可选）: 仅 true 输出。 */ -}}
  {{- if get $bools "hostIPC" }}
    {{- include "base.field" (list "hostIPC" true "base.bool") }}
  {{- end }}

  {{- /* hostNetwork（boolean, 可选）: 仅 true 输出。 */ -}}
  {{- if get $bools "hostNetwork" }}
    {{- include "base.field" (list "hostNetwork" true "base.bool") }}
  {{- end }}

  {{- /* hostPID（boolean, 可选）: 仅 true 输出。 */ -}}
  {{- if get $bools "hostPID" }}
    {{- include "base.field" (list "hostPID" true "base.bool") }}
  {{- end }}

  {{- /* hostUsers（boolean, 可选）: true 与 false 均输出。 */ -}}
  {{- if hasKey $bools "hostUsers" }}
    {{- include "base.field" (list "hostUsers" (get $bools "hostUsers") "base.bool") }}
  {{- end }}

  {{- /* hostname（string, 可选）: 按 RFC 1035 单段名称校验。 */ -}}
  {{- $hostname := mustRegexReplaceAll $_const.SYS.YAML_QUOTED (include "base.get" (list . "hostname") | trim) "$1" | trim }}
  {{- if $hostname }}
    {{- include "base.field" (list "hostname" (include "base.rfc" (list $hostname "1035")) "quote") }}
  {{- end }}

  {{- /* hostnameOverride（string, 可选）: 按 RFC 1123 单段名称校验。 */ -}}
  {{- if $hostnameOverride }}
    {{- include "base.field" (list "hostnameOverride" (include "base.rfc" (list $hostnameOverride "1123")) "quote") }}
  {{- end }}

  {{- /* imagePullSecrets（LocalObjectReference array, 可选）: 字符串项补齐 name 后逐项委托。 */ -}}
  {{- $_imagePullSecretsRaw := include "base.get" (list . "imagePullSecrets") | trim }}
  {{- if $_imagePullSecretsRaw }}
    {{- $_imagePullSecretsArr := $_imagePullSecretsRaw | fromYamlArray }}
    {{- if eq (include "base.isFromYamlArrayError" $_imagePullSecretsArr) "true" }}
      {{- fail "[core.podSpec] imagePullSecrets: must be array type" }}
    {{- end }}
    {{- $imagePullSecrets := list }}
    {{- range $_entry := $_imagePullSecretsArr }}
      {{- $_reference := dict }}
      {{- if kindIs "map" $_entry }}
        {{- $_reference = mustDeepCopy $_entry }}
      {{- else if kindIs "string" $_entry }}
        {{- $_reference = dict "name" $_entry }}
      {{- else }}
        {{- fail "[core.podSpec] imagePullSecrets: each item must be string or object type" }}
      {{- end }}
      {{- $_rendered := include "definitions.localObjectReference" $_reference | fromYaml }}
      {{- if and (ne (include "base.isFromYamlError" $_rendered) "true") $_rendered }}
        {{- $imagePullSecrets = mustAppend $imagePullSecrets $_rendered }}
      {{- end }}
    {{- end }}
    {{- $imagePullSecrets = mustUniq $imagePullSecrets }}
    {{- if $imagePullSecrets }}
      {{- include "base.field" (list "imagePullSecrets" $imagePullSecrets "base.slice") }}
    {{- end }}
  {{- end }}

  {{- /* initContainers（Container array, 可选）: 归一化与委托规则同 containers。 */ -}}
  {{- $_initContainersRaw := include "base.get" (list . "initContainers") | trim }}
  {{- if $_initContainersRaw }}
    {{- /* base.get 对数组输出顶层 YAML 序列，需用 fromYamlArray 恢复；失败时再按 map 形态解析为单元素数组。 */ -}}
    {{- $_initContainers := $_initContainersRaw | fromYamlArray }}
    {{- if eq (include "base.isFromYamlArrayError" $_initContainers) "true" }}
      {{- $_initContainers = $_initContainersRaw | fromYaml }}
      {{- if eq (include "base.isFromYamlError" $_initContainers) "true" }}
        {{- fail "[core.podSpec] initContainers: must be map or array type" }}
      {{- end }}
      {{- $_initContainers = list $_initContainers }}
    {{- end }}
    {{- $initContainers := list }}
    {{- range $_item := $_initContainers }}
      {{- if not (kindIs "map" $_item) }}
        {{- fail "[core.podSpec] initContainers: each item must be object type" }}
      {{- end }}
      {{- $_rendered := include "definitions.container" (mustMerge (dict "containers" $_item "os" $os) $containerExtras) | fromYaml }}
      {{- if and (ne (include "base.isFromYamlError" $_rendered) "true") $_rendered }}
        {{- $initContainers = mustAppend $initContainers $_rendered }}
      {{- end }}
    {{- end }}
    {{- $initContainers = mustUniq $initContainers }}
    {{- if $initContainers }}
      {{- include "base.field" (list "initContainers" $initContainers "base.slice") }}
    {{- end }}
  {{- end }}

  {{- /* nodeName（string, 可选）: 非空时输出原字符串。 */ -}}
  {{- $nodeName := mustRegexReplaceAll $_const.SYS.YAML_QUOTED (include "base.get" (list . "nodeName") | trim) "$1" | trim }}
  {{- if $nodeName }}
    {{- include "base.field" (list "nodeName" $nodeName "quote") }}
  {{- end }}

  {{- /* nodeSelector（object, 可选）: 非空 map 输出，其他类型失败。 */ -}}
  {{- $_nodeSelectorRaw := include "base.get" (list . "nodeSelector") | trim }}
  {{- if $_nodeSelectorRaw }}
    {{- $_nodeSelector := $_nodeSelectorRaw | fromYaml }}
    {{- if eq (include "base.isFromYamlError" $_nodeSelector) "true" }}
      {{- fail "[core.podSpec] nodeSelector: must be map type" }}
    {{- end }}
    {{- if $_nodeSelector }}
      {{- include "base.field" (list "nodeSelector" $_nodeSelector "base.map") }}
    {{- end }}
  {{- end }}

  {{- /* os（PodOS, 可选）: 委托归一化对象。 */ -}}
  {{- if $os }}
    {{- $_osRendered := include "definitions.podOS" $os | fromYaml }}
    {{- if and (ne (include "base.isFromYamlError" $_osRendered) "true") $_osRendered }}
      {{- include "base.field" (list "os" $_osRendered "base.map") }}
    {{- end }}
  {{- end }}

  {{- /* preemptionPolicy（string, 可选）: 按 Kubernetes 枚举校验。 */ -}}
  {{- $preemptionPolicy := mustRegexReplaceAll $_const.SYS.YAML_QUOTED (include "base.get" (list . "preemptionPolicy") | trim) "$1" | trim }}
  {{- if $preemptionPolicy }}
    {{- include "base.field" (list "preemptionPolicy" $preemptionPolicy "base.string" (list "Never" "PreemptLowerPriority")) }}
  {{- end }}

  {{- /* priorityClassName（string, 可选）: 非空时输出，不限制枚举。 */ -}}
  {{- $priorityClassName := mustRegexReplaceAll $_const.SYS.YAML_QUOTED (include "base.get" (list . "priorityClassName") | trim) "$1" | trim }}
  {{- if $priorityClassName }}
    {{- include "base.field" (list "priorityClassName" $priorityClassName "quote") }}
  {{- end }}

  {{- /* readinessGates（PodReadinessGate array, 可选）: 字符串项补齐 conditionType 后逐项委托。 */ -}}
  {{- $_readinessGatesRaw := include "base.get" (list . "readinessGates") | trim }}
  {{- if $_readinessGatesRaw }}
    {{- $_readinessGatesArr := $_readinessGatesRaw | fromYamlArray }}
    {{- if eq (include "base.isFromYamlArrayError" $_readinessGatesArr) "true" }}
      {{- fail "[core.podSpec] readinessGates: must be array type" }}
    {{- end }}
    {{- $readinessGates := list }}
    {{- range $_entry := $_readinessGatesArr }}
      {{- $_gate := dict }}
      {{- if kindIs "map" $_entry }}
        {{- $_gate = mustDeepCopy $_entry }}
      {{- else if kindIs "string" $_entry }}
        {{- $_gate = dict "conditionType" $_entry }}
      {{- else }}
        {{- fail "[core.podSpec] readinessGates: each item must be string or object type" }}
      {{- end }}
      {{- $_rendered := include "definitions.podReadinessGate" $_gate | fromYaml }}
      {{- if and (ne (include "base.isFromYamlError" $_rendered) "true") $_rendered }}
        {{- $readinessGates = mustAppend $readinessGates $_rendered }}
      {{- end }}
    {{- end }}
    {{- $readinessGates = mustUniq $readinessGates }}
    {{- if $readinessGates }}
      {{- include "base.field" (list "readinessGates" $readinessGates "base.slice") }}
    {{- end }}
  {{- end }}

  {{- /* resourceClaims（PodResourceClaim array, 可选）: 字符串最多拆为三段，缺省段不写入。 */ -}}
  {{- $_resourceClaimsRaw := include "base.get" (list . "resourceClaims") | trim }}
  {{- if $_resourceClaimsRaw }}
    {{- $_resourceClaimsArr := $_resourceClaimsRaw | fromYamlArray }}
    {{- if eq (include "base.isFromYamlArrayError" $_resourceClaimsArr) "true" }}
      {{- fail "[core.podSpec] resourceClaims: must be array type" }}
    {{- end }}
    {{- $resourceClaims := list }}
    {{- range $_entry := $_resourceClaimsArr }}
      {{- $_claim := dict }}
      {{- if kindIs "map" $_entry }}
        {{- $_claim = mustDeepCopy $_entry }}
      {{- else if kindIs "string" $_entry }}
        {{- $_parts := mustWithout (mustRegexSplit $_const.SPLIT.SPACE_COMMA (trim $_entry) -1) "" }}
        {{- if or (eq (len $_parts) 0) (gt (len $_parts) 3) }}
          {{- fail (printf "[core.podSpec] resourceClaims: '%s' must contain one to three segments" $_entry) }}
        {{- end }}
        {{- $_claim = dict "name" (toString (index $_parts 0)) }}
        {{- if ge (len $_parts) 2 }}
          {{- $_ = set $_claim "resourceClaimName" (toString (index $_parts 1)) }}
        {{- end }}
        {{- if ge (len $_parts) 3 }}
          {{- $_ = set $_claim "resourceClaimTemplateName" (toString (index $_parts 2)) }}
        {{- end }}
      {{- else }}
        {{- fail "[core.podSpec] resourceClaims: each item must be string or object type" }}
      {{- end }}
      {{- $_rendered := include "definitions.podResourceClaim" $_claim | fromYaml }}
      {{- if and (ne (include "base.isFromYamlError" $_rendered) "true") $_rendered }}
        {{- $resourceClaims = mustAppend $resourceClaims $_rendered }}
      {{- end }}
    {{- end }}
    {{- $resourceClaims = mustUniq $resourceClaims }}
    {{- if $resourceClaims }}
      {{- include "base.field" (list "resourceClaims" $resourceClaims "base.slice") }}
    {{- end }}
  {{- end }}

  {{- /* resources（ResourceRequirements, 可选）: 仅传递 claims、limits、requests。 */ -}}
  {{- $_resourcesRaw := include "base.get" (list . "resources") | trim }}
  {{- if $_resourcesRaw }}
    {{- $_resourcesParsed := $_resourcesRaw | fromYaml }}
    {{- if eq (include "base.isFromYamlError" $_resourcesParsed) "true" }}
      {{- fail "[core.podSpec] resources: must be map type" }}
    {{- end }}
    {{- $resources := pick (mustDeepCopy $_resourcesParsed) "claims" "limits" "requests" }}
    {{- if $resources }}
      {{- $_rendered := include "definitions.resourceRequirements" $resources | fromYaml }}
      {{- if and (ne (include "base.isFromYamlError" $_rendered) "true") $_rendered }}
        {{- include "base.field" (list "resources" $_rendered "base.map") }}
      {{- end }}
    {{- end }}
  {{- end }}

  {{- /* restartPolicy（string, 可选）: 按 Kubernetes 枚举校验。 */ -}}
  {{- $restartPolicy := mustRegexReplaceAll $_const.SYS.YAML_QUOTED (include "base.get" (list . "restartPolicy") | trim) "$1" | trim }}
  {{- if $restartPolicy }}
    {{- include "base.field" (list "restartPolicy" $restartPolicy "base.string" (list "Always" "Never" "OnFailure")) }}
  {{- end }}

  {{- /* runtimeClassName（string, 可选）: 非空时输出原字符串。 */ -}}
  {{- $runtimeClassName := mustRegexReplaceAll $_const.SYS.YAML_QUOTED (include "base.get" (list . "runtimeClassName") | trim) "$1" | trim }}
  {{- if $runtimeClassName }}
    {{- include "base.field" (list "runtimeClassName" $runtimeClassName "quote") }}
  {{- end }}

  {{- /* schedulerName（string, 可选）: 非空时输出原字符串。 */ -}}
  {{- $schedulerName := mustRegexReplaceAll $_const.SYS.YAML_QUOTED (include "base.get" (list . "schedulerName") | trim) "$1" | trim }}
  {{- if $schedulerName }}
    {{- include "base.field" (list "schedulerName" $schedulerName "quote") }}
  {{- end }}

  {{- /* securityContext（PodSecurityContext, 可选）: 复制原对象并注入同源 os 后委托。 */ -}}
  {{- $_securityContextRaw := include "base.get" (list . "securityContext") | trim }}
  {{- if $_securityContextRaw }}
    {{- $_securityContextParsed := $_securityContextRaw | fromYaml }}
    {{- if eq (include "base.isFromYamlError" $_securityContextParsed) "true" }}
      {{- fail "[core.podSpec] securityContext: must be map type" }}
    {{- end }}
    {{- if $_securityContextParsed }}
      {{- $securityContext := mustDeepCopy $_securityContextParsed }}
      {{- $_ = set $securityContext "os" $os }}
      {{- $_rendered := include "definitions.podSecurityContext" $securityContext | fromYaml }}
      {{- if and (ne (include "base.isFromYamlError" $_rendered) "true") $_rendered }}
        {{- include "base.field" (list "securityContext" $_rendered "base.map") }}
      {{- end }}
    {{- end }}
  {{- end }}

  {{- /* serviceAccountName（string, 可选）: 非空时输出原字符串。 */ -}}
  {{- $serviceAccountName := mustRegexReplaceAll $_const.SYS.YAML_QUOTED (include "base.get" (list . "serviceAccountName") | trim) "$1" | trim }}
  {{- if $serviceAccountName }}
    {{- include "base.field" (list "serviceAccountName" $serviceAccountName "quote") }}
  {{- end }}

  {{- /* setHostnameAsFQDN（boolean, 可选）: 仅 true 输出。 */ -}}
  {{- if get $bools "setHostnameAsFQDN" }}
    {{- include "base.field" (list "setHostnameAsFQDN" true "base.bool") }}
  {{- end }}

  {{- /* shareProcessNamespace（boolean, 可选）: 仅 true 输出。 */ -}}
  {{- if get $bools "shareProcessNamespace" }}
    {{- include "base.field" (list "shareProcessNamespace" true "base.bool") }}
  {{- end }}

  {{- /* subdomain（string, 可选）: 非空时输出原字符串并保持字符串类型。 */ -}}
  {{- $subdomain := mustRegexReplaceAll $_const.SYS.YAML_QUOTED (include "base.get" (list . "subdomain") | trim) "$1" | trim }}
  {{- if $subdomain }}
    {{- include "base.field" (list "subdomain" $subdomain "quote") }}
  {{- end }}

  {{- /* terminationGracePeriodSeconds（integer, 可选）: 接受非负整数，显式 0 也输出。 */ -}}
  {{- $terminationGracePeriodSeconds := mustRegexReplaceAll $_const.SYS.YAML_QUOTED (include "base.get" (list . "terminationGracePeriodSeconds") | trim) "$1" | trim }}
  {{- if $terminationGracePeriodSeconds }}
    {{- if not (mustRegexMatch $_const.TYPES.POSITIVE_INT $terminationGracePeriodSeconds) }}
      {{- fail (printf "[core.podSpec] terminationGracePeriodSeconds: must be a non-negative integer, got '%s'" $terminationGracePeriodSeconds) }}
    {{- end }}
    {{- include "base.field" (list "terminationGracePeriodSeconds" (include "base.int.positive" $terminationGracePeriodSeconds) "base.int") }}
  {{- end }}

  {{- /* tolerations（Toleration array, 可选）: 逐项以自身为上下文委托。 */ -}}
  {{- $_tolerationsRaw := include "base.get" (list . "tolerations") | trim }}
  {{- if $_tolerationsRaw }}
    {{- $_tolerationsArr := $_tolerationsRaw | fromYamlArray }}
    {{- if eq (include "base.isFromYamlArrayError" $_tolerationsArr) "true" }}
      {{- fail "[core.podSpec] tolerations: must be array type" }}
    {{- end }}
    {{- $tolerations := list }}
    {{- range $_entry := $_tolerationsArr }}
      {{- if not (kindIs "map" $_entry) }}
        {{- fail "[core.podSpec] tolerations: each item must be object type" }}
      {{- end }}
      {{- $_rendered := include "definitions.toleration" $_entry | fromYaml }}
      {{- if and (ne (include "base.isFromYamlError" $_rendered) "true") $_rendered }}
        {{- $tolerations = mustAppend $tolerations $_rendered }}
      {{- end }}
    {{- end }}
    {{- $tolerations = mustUniq $tolerations }}
    {{- if $tolerations }}
      {{- include "base.field" (list "tolerations" $tolerations "base.slice") }}
    {{- end }}
  {{- end }}

  {{- /* topologySpreadConstraints（TopologySpreadConstraint array, 可选）: 逐项以自身为上下文委托。 */ -}}
  {{- $_topologySpreadConstraintsRaw := include "base.get" (list . "topologySpreadConstraints") | trim }}
  {{- if $_topologySpreadConstraintsRaw }}
    {{- $_topologySpreadConstraintsArr := $_topologySpreadConstraintsRaw | fromYamlArray }}
    {{- if eq (include "base.isFromYamlArrayError" $_topologySpreadConstraintsArr) "true" }}
      {{- fail "[core.podSpec] topologySpreadConstraints: must be array type" }}
    {{- end }}
    {{- $topologySpreadConstraints := list }}
    {{- range $_entry := $_topologySpreadConstraintsArr }}
      {{- if not (kindIs "map" $_entry) }}
        {{- fail "[core.podSpec] topologySpreadConstraints: each item must be object type" }}
      {{- end }}
      {{- $_rendered := include "definitions.topologySpreadConstraint" $_entry | fromYaml }}
      {{- if and (ne (include "base.isFromYamlError" $_rendered) "true") $_rendered }}
        {{- $topologySpreadConstraints = mustAppend $topologySpreadConstraints $_rendered }}
      {{- end }}
    {{- end }}
    {{- $topologySpreadConstraints = mustUniq $topologySpreadConstraints }}
    {{- if $topologySpreadConstraints }}
      {{- include "base.field" (list "topologySpreadConstraints" $topologySpreadConstraints "base.slice") }}
    {{- end }}
  {{- end }}

  {{- /* volumes（Volume array, 可选）: 原生对象拆分为 type/name/data，字符串短写按常量捕获。 */ -}}
  {{- $_volumesRaw := include "base.get" (list . "volumes") | trim }}
  {{- if $_volumesRaw }}
    {{- $_volumesArr := $_volumesRaw | fromYamlArray }}
    {{- if eq (include "base.isFromYamlArrayError" $_volumesArr) "true" }}
      {{- fail "[core.podSpec] volumes: must be array type" }}
    {{- end }}
    {{- $volumeTypes := dict "cm" "configMap" "configmap" "configMap" "secret" "secret" "pvc" "persistentVolumeClaim" "persistentvolumeclaim" "persistentVolumeClaim" "emptydir" "emptyDir" "hostpath" "hostPath" "nfs" "nfs" "image" "image" "fc" "fc" "iscsi" "iscsi" }}
    {{- $volumes := list }}
    {{- range $_entry := $_volumesArr }}
      {{- $volume := dict }}
      {{- if kindIs "map" $_entry }}
        {{- $_ = set $volume "volumeName" (toString (get $_entry "name" | default "")) }}
        {{- $_volumeType := "" }}
        {{- range $_key, $_value := $_entry }}
          {{- if ne $_key "name" }}
            {{- if $_volumeType }}
              {{- fail (printf "[core.podSpec] volumes: '%s' has more than one volume type key" (get $volume "volumeName")) }}
            {{- end }}
            {{- $_volumeType = $_key }}
            {{- $_ = set $volume "volumeType" $_key }}
            {{- $_ = set $volume "volumeData" $_value }}
          {{- end }}
        {{- end }}
        {{- if not $_volumeType }}
          {{- fail (printf "[core.podSpec] volumes: '%s' must contain exactly one volume type key" (get $volume "volumeName")) }}
        {{- end }}
      {{- else if kindIs "string" $_entry }}
        {{- $_text := mustRegexReplaceAll $_const.SPLIT.SPACE_COMMA (trim $_entry) " " | trim }}
        {{- if not (mustRegexMatch $_const.K8S.VOLUME.SHORT $_text) }}
          {{- fail (printf "[core.podSpec] volumes: '%s' does not match the short form" $_entry) }}
        {{- end }}
        {{- $_volumeType := mustRegexReplaceAll $_const.K8S.VOLUME.SHORT $_text "$1" | trim }}
        {{- $_volumeName := mustRegexReplaceAll $_const.K8S.VOLUME.SHORT $_text "$2" | trim }}
        {{- $_volumeData := mustRegexReplaceAll $_const.K8S.VOLUME.SHORT $_text "$3" | trim }}
        {{- $_ = set $volume "volumeType" $_volumeType }}
        {{- $_ = set $volume "volumeName" $_volumeName }}
        {{- if $_volumeData }}
          {{- $_ = set $volume "volumeData" $_volumeData }}
        {{- end }}
      {{- else }}
        {{- fail "[core.podSpec] volumes: each item must be string or object type" }}
      {{- end }}
      {{- $_volumeType := toString (get $volume "volumeType") }}
      {{- if hasKey $volumeTypes (lower $_volumeType) }}
        {{- $_ = set $volume "volumeType" (get $volumeTypes (lower $_volumeType)) }}
      {{- end }}
      {{- $_rendered := include "definitions.Volume" $volume | fromYaml }}
      {{- if and (ne (include "base.isFromYamlError" $_rendered) "true") $_rendered }}
        {{- $volumes = mustAppend $volumes $_rendered }}
      {{- end }}
    {{- end }}
    {{- $volumes = mustUniq $volumes }}
    {{- if $volumes }}
      {{- include "base.field" (list "volumes" $volumes "base.slice") }}
    {{- end }}
  {{- end }}
{{- end }}
