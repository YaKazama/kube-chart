{{- /*
  渲染 Kubernetes DeploymentSpec 字段片段。

  行为 (按 K8s API 规范字段顺序):
    - minReadySeconds (integer, 可选): 只接受原生整数，缺失与 0 不输出，正值输出，上限 2147483647。
    - paused (boolean, 可选): 缺失时使用 false，只接受原生 boolean。
    - progressDeadlineSeconds (integer, 可选): 只接受原生整数，缺失与 0 不输出，正值输出，上限 2147483647。
    - replicas (integer, 可选): 只接受原生整数，缺失不输出，允许显式 0，上限 2147483647。
    - revisionHistoryLimit (integer, 可选): 只接受原生整数，缺失与 0 不输出，正值输出，上限 2147483647。
    - selector (LabelSelector, 必填): 合并基础标签后委托 definitions.labelSelector 渲染。
    - strategy (DeploymentStrategy, 可选): 归一化 map 或字符串简写后委托 apps.deploymentStrategy 渲染。
    - template (PodTemplateSpec, 必填): 透传原始上下文并委托 core.podTemplateSpec 渲染。

  边界:
    - 只输出 DeploymentSpec 当前层字段，不包含 spec 父键；不解析 LabelSelector、DeploymentStrategy 与 PodTemplateSpec 的内部结构。
    - 四个整数字段均不内置默认值，缺失或为空时不输出，由 Kubernetes API 自身默认值生效。

  入参: 上下文 map，可包含上述 DeploymentSpec 字段以及基础标签和 PodTemplateSpec 所需上下文。

  返回值: 可嵌入 Deployment 的 spec 下的 DeploymentSpec YAML 字段片段。

  示例:
    {{- include "apps.deploymentSpec" (dict "selector" (dict)) }}
*/ -}}
{{- define "apps.deploymentSpec" -}}
  {{- $_const := include "base.env" "" | fromYaml }}

  {{- /* minReadySeconds（integer）: 缺失或为空时不输出，由 API 默认值生效；仅正整数渲染，显式 0 视为 0 值不输出，上限 2147483647。 */ -}}
  {{- $_minReadySecondsRaw := include "base.get" (list . "minReadySeconds") }}
  {{- if $_minReadySecondsRaw }}
    {{- $_minReadySecondsValue := int (include "base.int.range" (list (int (include "base.int" $_minReadySecondsRaw)) 0 2147483647)) }}
    {{- if gt $_minReadySecondsValue 0 }}
      {{- include "base.field" (list "minReadySeconds" $_minReadySecondsValue "base.int") }}
    {{- end }}
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

  {{- /* progressDeadlineSeconds（integer）: 缺失或为空时不输出，由 API 默认值生效；仅正整数渲染，显式 0 视为 0 值不输出，上限 2147483647。 */ -}}
  {{- $_progressDeadlineSecondsRaw := include "base.get" (list . "progressDeadlineSeconds") }}
  {{- if $_progressDeadlineSecondsRaw }}
    {{- $_progressDeadlineSecondsValue := int (include "base.int.range" (list (int (include "base.int" $_progressDeadlineSecondsRaw)) 0 2147483647)) }}
    {{- if gt $_progressDeadlineSecondsValue 0 }}
      {{- include "base.field" (list "progressDeadlineSeconds" $_progressDeadlineSecondsValue "base.int") }}
    {{- end }}
  {{- end }}

  {{- /* replicas（integer）: 缺失或为空时不输出，由 API 默认值生效；允许显式 0 并渲染 0，上限 2147483647。 */ -}}
  {{- $_replicasRaw := include "base.get" (list . "replicas") }}
  {{- if $_replicasRaw }}
    {{- include "base.field" (list "replicas" (int (include "base.int.range" (list (int (include "base.int" $_replicasRaw)) 0 2147483647))) "base.int") }}
  {{- end }}

  {{- /* revisionHistoryLimit（integer）: 缺失或为空时不输出，由 API 默认值生效；仅正整数渲染，显式 0 视为 0 值不输出，上限 2147483647。 */ -}}
  {{- $_revisionHistoryLimitRaw := include "base.get" (list . "revisionHistoryLimit") }}
  {{- if $_revisionHistoryLimitRaw }}
    {{- $_revisionHistoryLimitValue := int (include "base.int.range" (list (int (include "base.int" $_revisionHistoryLimitRaw)) 0 2147483647)) }}
    {{- if gt $_revisionHistoryLimitValue 0 }}
      {{- include "base.field" (list "revisionHistoryLimit" $_revisionHistoryLimitValue "base.int") }}
    {{- end }}
  {{- end }}

  {{- /* selector（LabelSelector）: 必填，清洗字段并以用户标签左优合并基础标签后委托渲染。 */ -}}
  {{- $_selectorRaw := include "base.get" (list . "selector") }}
  {{- if not $_selectorRaw }}
    {{- fail "[apps.deploymentSpec] selector: required field is missing or null" }}
  {{- end }}
  {{- $_selectorParsed := $_selectorRaw | fromYaml }}
  {{- if eq (include "base.isFromYamlError" $_selectorParsed) "true" }}
    {{- fail "[apps.deploymentSpec] selector: must be map type" }}
  {{- end }}
  {{- $_selector := pick $_selectorParsed "matchExpressions" "matchLabels" "matchExpressionsAlias" "matchLabelsAlias" }}
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

  {{- /* strategy（DeploymentStrategy）: 可选，将 map 或字符串简写归一化后委托 apps.deploymentStrategy 渲染。 */ -}}
  {{- $_strategyRaw := include "base.get" (list . "strategy") }}
  {{- if $_strategyRaw }}
    {{- $_strategyParsed := $_strategyRaw | fromYaml }}
    {{- $_strategyIsError := eq (include "base.isFromYamlError" $_strategyParsed) "true" }}
    {{- $strategy := dict }}

    {{- if not $_strategyIsError }}
      {{- $_strategyTypeRaw := include "base.get" (list $_strategyParsed "type") }}
      {{- $strategyType := "RollingUpdate" }}
      {{- if $_strategyTypeRaw }}
        {{- $strategyType = include "base.string.normalize" $_strategyTypeRaw | trim }}
        {{- if eq (lower $strategyType) "recreate" }}
          {{- $strategyType = "Recreate" }}
        {{- else if eq (lower $strategyType) "rollingupdate" }}
          {{- $strategyType = "RollingUpdate" }}
        {{- end }}
      {{- end }}
      {{- $_ := set $strategy "type" $strategyType }}

      {{- if ne $strategyType "Recreate" }}
        {{- $_strategyRollingUpdateRaw := include "base.get" (list $_strategyParsed "rollingUpdate") | trim }}
        {{- if $_strategyRollingUpdateRaw }}
          {{- $strategyRollingUpdate := $_strategyRollingUpdateRaw | fromYaml }}
          {{- if or (eq (include "base.isFromYamlError" $strategyRollingUpdate) "true") (not (kindIs "map" $strategyRollingUpdate)) }}
            {{- fail "[apps.deploymentSpec] strategy: rollingUpdate must be map type" }}
          {{- end }}
          {{- if $strategyRollingUpdate }}
            {{- $_ := set $strategy "rollingUpdate" (mustDeepCopy $strategyRollingUpdate) }}
          {{- end }}
        {{- end }}
      {{- end }}

    {{- else }}
      {{- $_strategyString := include "base.string.normalize" $_strategyRaw | trim }}
      {{- if not (mustRegexMatch $_const.APPS.DEPLOYMENT.STRATEGY $_strategyString) }}
        {{- fail "[apps.deploymentSpec] strategy: string does not match the supported strategy format" }}
      {{- end }}
      {{- $_strategyType := trimAll "\"'" (mustRegexReplaceAll $_const.APPS.DEPLOYMENT.STRATEGY $_strategyString "$1") | trim }}
      {{- $_strategyMaxSurge := trimAll "\"'" (mustRegexReplaceAll $_const.APPS.DEPLOYMENT.STRATEGY $_strategyString "$2") | trim }}
      {{- $_strategyMaxUnavailable := trimAll "\"'" (mustRegexReplaceAll $_const.APPS.DEPLOYMENT.STRATEGY $_strategyString "$3") | trim }}

      {{- if or $_strategyType $_strategyMaxSurge $_strategyMaxUnavailable }}
        {{- $_strategyTypeName := ternary "Recreate" "RollingUpdate" (eq "recreate" (lower $_strategyType)) }}
        {{- $_ := set $strategy "type" $_strategyTypeName }}

        {{- if eq $_strategyTypeName "RollingUpdate" }}
          {{- $_strategyRollingUpdate := dict }}
          {{- if $_strategyMaxSurge }}
            {{- $_ := set $_strategyRollingUpdate "maxSurge" $_strategyMaxSurge }}
          {{- end }}
          {{- if $_strategyMaxUnavailable }}
            {{- $_ := set $_strategyRollingUpdate "maxUnavailable" $_strategyMaxUnavailable }}
          {{- end }}
          {{- if $_strategyRollingUpdate }}
            {{- $_ := set $strategy "rollingUpdate" $_strategyRollingUpdate }}
          {{- end }}
        {{- end }}
      {{- end }}
    {{- end }}

    {{- if $strategy }}
      {{- $strategyOutput := include "apps.deploymentStrategy" $strategy | fromYaml }}
      {{- if eq (include "base.isFromYamlError" $strategyOutput) "true" }}
        {{- fail "[apps.deploymentSpec] strategy: apps.deploymentStrategy returned invalid YAML" }}
      {{- end }}
      {{- if not $strategyOutput }}
        {{- fail "[apps.deploymentSpec] strategy: apps.deploymentStrategy returned empty output" }}
      {{- end }}
      {{- include "base.field" (list "strategy" $strategyOutput "base.map") }}
    {{- end }}
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
