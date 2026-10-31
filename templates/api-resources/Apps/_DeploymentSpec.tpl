{{- /*
  渲染 Kubernetes DeploymentSpec 字段片段。

  行为 (按 K8s API 规范字段顺序):
    - minReadySeconds (integer, 可选): 缺失时使用 0，负数抑制输出，并限制在 int32 非负上限内。
    - paused (boolean, 可选): 缺失时使用 false，只接受原生 boolean。
    - progressDeadlineSeconds (integer, 可选): 缺失时使用 600，负数抑制输出，并限制在 int32 非负上限内。
    - replicas (integer, 可选): 缺失时使用 1，负数抑制输出，并限制在 int32 非负上限内。
    - revisionHistoryLimit (integer, 可选): 缺失时使用 10，负数抑制输出，并限制在 int32 非负上限内。
    - selector (LabelSelector, 必填): 合并基础标签后委托 definitions.labelSelector 渲染。
    - strategy (DeploymentStrategy, 可选): 归一化 map 或字符串简写后委托 definitions.deploymentStrategy 渲染。
    - template (PodTemplateSpec, 必填): 透传原始上下文并委托 core.podTemplateSpec 渲染。

  边界: 只输出 DeploymentSpec 当前层字段，不包含 spec 父键；不解析 LabelSelector、DeploymentStrategy 与 PodTemplateSpec 的内部结构。

  入参: 上下文 map，可包含上述 DeploymentSpec 字段以及基础标签和 PodTemplateSpec 所需上下文。

  返回值: 可嵌入 Deployment 的 spec 下的 DeploymentSpec YAML 字段片段。

  示例:
    {{- include "apps.deploymentSpec" (dict "selector" (dict)) }}
*/ -}}
{{- define "apps.deploymentSpec" -}}
  {{- $_const := include "base.env" "" | fromYaml }}

  {{- /* minReadySeconds（integer）: 缺失时使用建议值，负数抑制输出，并校验非负上限。 */ -}}
  {{- $_minReadySecondsRaw := include "base.get" (list . "minReadySeconds") | trim }}
  {{- if not $_minReadySecondsRaw }}
    {{- $_minReadySecondsRaw = "0" }}
  {{- end }}
  {{- $_minReadySecondsValue := mustRegexReplaceAll $_const.SYS.YAML_QUOTED $_minReadySecondsRaw "$1" | trim }}
  {{- $_minReadySecondsIsInteger := ne $_minReadySecondsValue "" }}
  {{- $_minReadySecondsUnsigned := $_minReadySecondsValue }}
  {{- if or (hasPrefix "+" $_minReadySecondsUnsigned) (hasPrefix "-" $_minReadySecondsUnsigned) }}
    {{- $_minReadySecondsUnsigned = substr 1 (len $_minReadySecondsUnsigned) $_minReadySecondsUnsigned }}
  {{- end }}
  {{- if not $_minReadySecondsUnsigned }}
    {{- $_minReadySecondsIsInteger = false }}
  {{- end }}
  {{- range $_index := until (len $_minReadySecondsUnsigned) }}
    {{- $_digit := substr $_index (add $_index 1 | int) $_minReadySecondsUnsigned }}
    {{- if not (contains $_digit "0123456789") }}
      {{- $_minReadySecondsIsInteger = false }}
    {{- end }}
  {{- end }}
  {{- if not $_minReadySecondsIsInteger }}
    {{- fail "[apps.deploymentSpec] minReadySeconds: must be an integer or integer string" }}
  {{- end }}
  {{- $_minReadySecondsValidated := include "base.int" $_minReadySecondsValue }}
  {{- $_minReadySecondsNegative := hasPrefix "-" $_minReadySecondsValidated }}
  {{- $_minReadySecondsDigits := $_minReadySecondsUnsigned }}
  {{- range until (len $_minReadySecondsDigits) }}
    {{- if and (gt (len $_minReadySecondsDigits) 1) (hasPrefix "0" $_minReadySecondsDigits) }}
      {{- $_minReadySecondsDigits = trimPrefix "0" $_minReadySecondsDigits }}
    {{- end }}
  {{- end }}
  {{- if and (not $_minReadySecondsNegative) (or (gt (len $_minReadySecondsDigits) 10) (and (eq (len $_minReadySecondsDigits) 10) (gt $_minReadySecondsDigits "2147483647"))) }}
    {{- fail "[apps.deploymentSpec] minReadySeconds: must not exceed 2147483647" }}
  {{- end }}
  {{- if or (not $_minReadySecondsNegative) (eq $_minReadySecondsDigits "0") }}
    {{- include "base.field" (list "minReadySeconds" (int64 $_minReadySecondsDigits) "base.int") }}
  {{- end }}

  {{- /* paused（boolean）: 缺失时使用 false，只接受原生 boolean。 */ -}}
  {{- $_pausedRaw := include "base.get" (list . "paused") | trim }}
  {{- if not $_pausedRaw }}
    {{- $_pausedRaw = "false" }}
  {{- end }}
  {{- if not (or (eq $_pausedRaw "true") (eq $_pausedRaw "false")) }}
    {{- fail "[apps.deploymentSpec] paused: must be a native boolean" }}
  {{- end }}
  {{- include "base.field" (list "paused" (eq $_pausedRaw "true") "base.bool") }}

  {{- /* progressDeadlineSeconds（integer）: 缺失时使用建议值，负数抑制输出，并校验非负上限。 */ -}}
  {{- $_progressDeadlineSecondsRaw := include "base.get" (list . "progressDeadlineSeconds") | trim }}
  {{- if not $_progressDeadlineSecondsRaw }}
    {{- $_progressDeadlineSecondsRaw = "600" }}
  {{- end }}
  {{- $_progressDeadlineSecondsValue := mustRegexReplaceAll $_const.SYS.YAML_QUOTED $_progressDeadlineSecondsRaw "$1" | trim }}
  {{- $_progressDeadlineSecondsIsInteger := ne $_progressDeadlineSecondsValue "" }}
  {{- $_progressDeadlineSecondsUnsigned := $_progressDeadlineSecondsValue }}
  {{- if or (hasPrefix "+" $_progressDeadlineSecondsUnsigned) (hasPrefix "-" $_progressDeadlineSecondsUnsigned) }}
    {{- $_progressDeadlineSecondsUnsigned = substr 1 (len $_progressDeadlineSecondsUnsigned) $_progressDeadlineSecondsUnsigned }}
  {{- end }}
  {{- if not $_progressDeadlineSecondsUnsigned }}
    {{- $_progressDeadlineSecondsIsInteger = false }}
  {{- end }}
  {{- range $_index := until (len $_progressDeadlineSecondsUnsigned) }}
    {{- $_digit := substr $_index (add $_index 1 | int) $_progressDeadlineSecondsUnsigned }}
    {{- if not (contains $_digit "0123456789") }}
      {{- $_progressDeadlineSecondsIsInteger = false }}
    {{- end }}
  {{- end }}
  {{- if not $_progressDeadlineSecondsIsInteger }}
    {{- fail "[apps.deploymentSpec] progressDeadlineSeconds: must be an integer or integer string" }}
  {{- end }}
  {{- $_progressDeadlineSecondsValidated := include "base.int" $_progressDeadlineSecondsValue }}
  {{- $_progressDeadlineSecondsNegative := hasPrefix "-" $_progressDeadlineSecondsValidated }}
  {{- $_progressDeadlineSecondsDigits := $_progressDeadlineSecondsUnsigned }}
  {{- range until (len $_progressDeadlineSecondsDigits) }}
    {{- if and (gt (len $_progressDeadlineSecondsDigits) 1) (hasPrefix "0" $_progressDeadlineSecondsDigits) }}
      {{- $_progressDeadlineSecondsDigits = trimPrefix "0" $_progressDeadlineSecondsDigits }}
    {{- end }}
  {{- end }}
  {{- if and (not $_progressDeadlineSecondsNegative) (or (gt (len $_progressDeadlineSecondsDigits) 10) (and (eq (len $_progressDeadlineSecondsDigits) 10) (gt $_progressDeadlineSecondsDigits "2147483647"))) }}
    {{- fail "[apps.deploymentSpec] progressDeadlineSeconds: must not exceed 2147483647" }}
  {{- end }}
  {{- if or (not $_progressDeadlineSecondsNegative) (eq $_progressDeadlineSecondsDigits "0") }}
    {{- include "base.field" (list "progressDeadlineSeconds" (int64 $_progressDeadlineSecondsDigits) "base.int") }}
  {{- end }}

  {{- /* replicas（integer）: 缺失时使用建议值，负数抑制输出，并校验非负上限。 */ -}}
  {{- $_replicasRaw := include "base.get" (list . "replicas") | trim }}
  {{- if not $_replicasRaw }}
    {{- $_replicasRaw = "1" }}
  {{- end }}
  {{- $_replicasValue := mustRegexReplaceAll $_const.SYS.YAML_QUOTED $_replicasRaw "$1" | trim }}
  {{- $_replicasIsInteger := ne $_replicasValue "" }}
  {{- $_replicasUnsigned := $_replicasValue }}
  {{- if or (hasPrefix "+" $_replicasUnsigned) (hasPrefix "-" $_replicasUnsigned) }}
    {{- $_replicasUnsigned = substr 1 (len $_replicasUnsigned) $_replicasUnsigned }}
  {{- end }}
  {{- if not $_replicasUnsigned }}
    {{- $_replicasIsInteger = false }}
  {{- end }}
  {{- range $_index := until (len $_replicasUnsigned) }}
    {{- $_digit := substr $_index (add $_index 1 | int) $_replicasUnsigned }}
    {{- if not (contains $_digit "0123456789") }}
      {{- $_replicasIsInteger = false }}
    {{- end }}
  {{- end }}
  {{- if not $_replicasIsInteger }}
    {{- fail "[apps.deploymentSpec] replicas: must be an integer or integer string" }}
  {{- end }}
  {{- $_replicasValidated := include "base.int" $_replicasValue }}
  {{- $_replicasNegative := hasPrefix "-" $_replicasValidated }}
  {{- $_replicasDigits := $_replicasUnsigned }}
  {{- range until (len $_replicasDigits) }}
    {{- if and (gt (len $_replicasDigits) 1) (hasPrefix "0" $_replicasDigits) }}
      {{- $_replicasDigits = trimPrefix "0" $_replicasDigits }}
    {{- end }}
  {{- end }}
  {{- if and (not $_replicasNegative) (or (gt (len $_replicasDigits) 10) (and (eq (len $_replicasDigits) 10) (gt $_replicasDigits "2147483647"))) }}
    {{- fail "[apps.deploymentSpec] replicas: must not exceed 2147483647" }}
  {{- end }}
  {{- if or (not $_replicasNegative) (eq $_replicasDigits "0") }}
    {{- include "base.field" (list "replicas" (int64 $_replicasDigits) "base.int") }}
  {{- end }}

  {{- /* revisionHistoryLimit（integer）: 缺失时使用建议值，负数抑制输出，并校验非负上限。 */ -}}
  {{- $_revisionHistoryLimitRaw := include "base.get" (list . "revisionHistoryLimit") | trim }}
  {{- if not $_revisionHistoryLimitRaw }}
    {{- $_revisionHistoryLimitRaw = "10" }}
  {{- end }}
  {{- $_revisionHistoryLimitValue := mustRegexReplaceAll $_const.SYS.YAML_QUOTED $_revisionHistoryLimitRaw "$1" | trim }}
  {{- $_revisionHistoryLimitIsInteger := ne $_revisionHistoryLimitValue "" }}
  {{- $_revisionHistoryLimitUnsigned := $_revisionHistoryLimitValue }}
  {{- if or (hasPrefix "+" $_revisionHistoryLimitUnsigned) (hasPrefix "-" $_revisionHistoryLimitUnsigned) }}
    {{- $_revisionHistoryLimitUnsigned = substr 1 (len $_revisionHistoryLimitUnsigned) $_revisionHistoryLimitUnsigned }}
  {{- end }}
  {{- if not $_revisionHistoryLimitUnsigned }}
    {{- $_revisionHistoryLimitIsInteger = false }}
  {{- end }}
  {{- range $_index := until (len $_revisionHistoryLimitUnsigned) }}
    {{- $_digit := substr $_index (add $_index 1 | int) $_revisionHistoryLimitUnsigned }}
    {{- if not (contains $_digit "0123456789") }}
      {{- $_revisionHistoryLimitIsInteger = false }}
    {{- end }}
  {{- end }}
  {{- if not $_revisionHistoryLimitIsInteger }}
    {{- fail "[apps.deploymentSpec] revisionHistoryLimit: must be an integer or integer string" }}
  {{- end }}
  {{- $_revisionHistoryLimitValidated := include "base.int" $_revisionHistoryLimitValue }}
  {{- $_revisionHistoryLimitNegative := hasPrefix "-" $_revisionHistoryLimitValidated }}
  {{- $_revisionHistoryLimitDigits := $_revisionHistoryLimitUnsigned }}
  {{- range until (len $_revisionHistoryLimitDigits) }}
    {{- if and (gt (len $_revisionHistoryLimitDigits) 1) (hasPrefix "0" $_revisionHistoryLimitDigits) }}
      {{- $_revisionHistoryLimitDigits = trimPrefix "0" $_revisionHistoryLimitDigits }}
    {{- end }}
  {{- end }}
  {{- if and (not $_revisionHistoryLimitNegative) (or (gt (len $_revisionHistoryLimitDigits) 10) (and (eq (len $_revisionHistoryLimitDigits) 10) (gt $_revisionHistoryLimitDigits "2147483647"))) }}
    {{- fail "[apps.deploymentSpec] revisionHistoryLimit: must not exceed 2147483647" }}
  {{- end }}
  {{- if or (not $_revisionHistoryLimitNegative) (eq $_revisionHistoryLimitDigits "0") }}
    {{- include "base.field" (list "revisionHistoryLimit" (int64 $_revisionHistoryLimitDigits) "base.int") }}
  {{- end }}

  {{- /* selector（LabelSelector）: 必填，清洗字段并以用户标签左优合并基础标签后委托渲染。 */ -}}
  {{- $_selectorRaw := include "base.get" (list . "selector") }}
  {{- if or (not $_selectorRaw) (eq ($_selectorRaw | trim) "null") }}
    {{- fail "[apps.deploymentSpec] selector: required field is missing or null" }}
  {{- end }}
  {{- $_selectorParsed := $_selectorRaw | fromYaml }}
  {{- if eq (include "base.isFromYamlError" $_selectorParsed) "true" }}
    {{- fail "[apps.deploymentSpec] selector: must be map type" }}
  {{- end }}
  {{- $_selector := pick $_selectorParsed "matchExpressions" "matchLabels" }}
  {{- $_baseLabels := include "base.labels" . | fromYaml }}
  {{- if eq (include "base.isFromYamlError" $_baseLabels) "true" }}
    {{- fail "[apps.deploymentSpec] selector: base.labels returned invalid YAML" }}
  {{- end }}

  {{- $selector := mustMerge $_selector (dict "matchLabels" $_baseLabels) }}
  {{- $selectorOutput := include "definitions.labelSelector" $selector | fromYaml }}
  {{- if eq (include "base.isFromYamlError" $selectorOutput) "true" }}
    {{- fail "[apps.deploymentSpec] selector: definitions.labelSelector returned invalid YAML" }}
  {{- end }}
  {{- if empty $selectorOutput }}
    {{- fail "[apps.deploymentSpec] selector: definitions.labelSelector returned empty output" }}
  {{- end }}
  {{- include "base.field" (list "selector" $selectorOutput "base.map") }}

  {{- /* strategy（DeploymentStrategy）: 可选，将 map 或字符串简写归一化后委托渲染。 */ -}}
  {{- $_strategyRaw := include "base.get" (list . "strategy") }}
  {{- if $_strategyRaw }}
    {{- if eq ($_strategyRaw | trim) "null" }}
      {{- fail "[apps.deploymentSpec] strategy: must be map or string type" }}
    {{- end }}
    {{- $_strategyParsed := $_strategyRaw | fromYaml }}
    {{- $_strategyIsError := eq (include "base.isFromYamlError" $_strategyParsed) "true" }}
    {{- $strategy := dict }}

    {{- if and (not $_strategyIsError) (kindIs "map" $_strategyParsed) }}
      {{- range $_key := list "type" "rollingUpdate" }}
        {{- if hasKey $_strategyParsed $_key }}
          {{- $_ := set $strategy $_key (mustDeepCopy (get $_strategyParsed $_key)) }}
        {{- end }}
      {{- end }}

    {{- else if $_strategyIsError }}
      {{- $_strategyString := mustRegexReplaceAll $_const.SYS.YAML_QUOTED ($_strategyRaw | trim) "$1" | trim }}
      {{- if not (mustRegexMatch $_const.APPS.DEPLOYMENT.STRATEGY $_strategyString) }}
        {{- fail "[apps.deploymentSpec] strategy: string does not match the supported strategy format" }}
      {{- end }}
      {{- $_strategyType := mustRegexReplaceAll $_const.APPS.DEPLOYMENT.STRATEGY $_strategyString "$1" | trim }}
      {{- $_strategyRollingUpdate := mustRegexReplaceAll $_const.APPS.DEPLOYMENT.STRATEGY $_strategyString "$2" | trim }}
      {{- $strategy = dict "type" $_strategyType "rollingUpdate" $_strategyRollingUpdate }}

    {{- else }}
      {{- fail "[apps.deploymentSpec] strategy: must be map or string type" }}
    {{- end }}
    {{- $_strategyOutputRaw := include "definitions.deploymentStrategy" $strategy }}
    {{- if not $_strategyOutputRaw }}
      {{- fail "[apps.deploymentSpec] strategy: definitions.deploymentStrategy returned empty output" }}
    {{- end }}
    {{- if eq ($_strategyOutputRaw | trim) "null" }}
      {{- fail "[apps.deploymentSpec] strategy: definitions.deploymentStrategy must return map type" }}
    {{- end }}
    {{- $strategyOutput := $_strategyOutputRaw | fromYaml }}
    {{- if eq (include "base.isFromYamlError" $strategyOutput) "true" }}
      {{- fail "[apps.deploymentSpec] strategy: definitions.deploymentStrategy returned invalid YAML" }}
    {{- end }}
    {{- if not (kindIs "map" $strategyOutput) }}
      {{- fail "[apps.deploymentSpec] strategy: definitions.deploymentStrategy must return map type" }}
    {{- end }}
    {{- include "base.field" (list "strategy" $strategyOutput "base.map") }}
  {{- end }}

  {{- /* template（PodTemplateSpec）: 必填，透传原始上下文并委托渲染。 */ -}}
  {{- $template := include "core.podTemplateSpec" . | fromYaml }}
  {{- if eq (include "base.isFromYamlError" $template) "true" }}
    {{- fail "[apps.deploymentSpec] template: core.podTemplateSpec returned invalid YAML" }}
  {{- end }}
  {{- if empty $template }}
    {{- fail "[apps.deploymentSpec] template: core.podTemplateSpec returned empty output" }}
  {{- end }}
  {{- include "base.field" (list "template" $template "base.map") }}
{{- end }}
