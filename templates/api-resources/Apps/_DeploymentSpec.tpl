{{- /*
  渲染 Kubernetes DeploymentSpec 资源。参考 https://kubernetes.io/docs/reference/kubernetes-api/apps/deployment-v1/#DeploymentSpec

  行为 (按 K8s API 规范字段顺序):
    - minReadySeconds (int, 可选): 仅在显式值 > 0 时渲染, 缺省时由 K8s 默认为 0, 显式值 < 0 时不渲染。
    - paused (bool, 可选): 仅在显式设置为 true 时渲染, 缺省时由 K8s 默认为 false。
    - progressDeadlineSeconds (int, 可选): 仅在显式值 > 0 时渲染, 缺省时由 K8s 默认为 600, 显式值 <= 0 时不渲染。
    - replicas (int, 可选): 仅在显式值 >= 0 时渲染, 缺省时由 K8s 默认为 1 (允许显式 0 表示缩容到零), 显式值 < 0 时不渲染。
    - revisionHistoryLimit (int, 可选): 仅在显式值 >= 0 时渲染, 缺省时由 K8s 默认为 10, 显式值 < 0 时不渲染。
    - selector (object, 必填): 委托 definitions.labelSelector 渲染。
    - strategy (string/object, 可选): 委托 apps.deploymentStrategy 渲染。
    - template (object, 必填): 委托 core.podTemplateSpec 渲染。

  核心字段: 上下文 map, 可包含以下字段:
    - minReadySeconds          (int, 可选)         Pod 处于 Ready 状态的最短秒数 (> 0)
    - paused                   (bool, 可选)        部署是否被暂停
    - progressDeadlineSeconds  (int, 可选)         Deployment 进度更新超时秒数 (> 0)
    - replicas                 (int, 可选)         Pod 副本数 (>= 0, 0 表示缩容到零)
    - revisionHistoryLimit     (int, 可选)         保留的历史 ReplicaSet 数量 (>= 0)
    - selector                 (object, 必填)      LabelSelector 结构, matchLabels 必填, matchExpressions 可选
    - strategy                 (string/object, 可选) DeploymentStrategy 结构
    - template                 (object, 必填)      PodTemplateSpec 结构

  返回值: DeploymentSpec 资源 YAML 键值对 (不含 spec 父键), 由调用方包入 spec 块

  示例:
    {{- include "apps.deploymentSpec" . }}
*/ -}}
{{- define "apps.deploymentSpec" -}}
  {{- /* Step 1: minReadySeconds (int, 可选): 仅在显式值 > 0 时渲染, 缺省时由 K8s 默认为 0
       约束: 显式值 < 0 时不渲染 (0 等同缺省, 负数非法)
       注: 兼容 Helm 4.2.2 fromYaml 对基本类型返回错误 map 的 BUG, 直接 atoi 解析 base.get 输出 */ -}}
  {{- $_minReadySecondsRaw := include "base.get" (list . "minReadySeconds" "int") | trim }}
  {{- if $_minReadySecondsRaw }}
    {{- $_minReadySeconds := atoi $_minReadySecondsRaw }}
    {{- if gt $_minReadySeconds 0 }}
      {{- include "base.field" (list "minReadySeconds" $_minReadySeconds "base.int") }}
    {{- end }}
  {{- end }}

  {{- /* Step 2: paused (bool, 可选): 仅在显式设置为 true 时渲染, K8s 缺省为 false
       注: 兼容 Helm 4.2.2 fromYaml 对基本类型返回错误 map 的 BUG, 直接比较 base.get 输出字符串 */ -}}
  {{- $_pausedRaw := include "base.get" (list . "paused") | trim }}
  {{- if eq $_pausedRaw "true" }}
    {{- include "base.field" (list "paused" true "base.bool") }}
  {{- end }}

  {{- /* Step 3: progressDeadlineSeconds (int, 可选): 仅在显式值 > 0 时渲染, 缺省时由 K8s 默认为 600
       约束: 显式值 <= 0 时不渲染 (0 和负数均非法)
       注: 兼容 Helm 4.2.2 fromYaml 对基本类型返回错误 map 的 BUG, 直接 atoi 解析 base.get 输出 */ -}}
  {{- $_progressDeadlineSecondsRaw := include "base.get" (list . "progressDeadlineSeconds" "int") | trim }}
  {{- if $_progressDeadlineSecondsRaw }}
    {{- $_progressDeadlineSeconds := atoi $_progressDeadlineSecondsRaw }}
    {{- if gt $_progressDeadlineSeconds 0 }}
      {{- include "base.field" (list "progressDeadlineSeconds" $_progressDeadlineSeconds "base.int") }}
    {{- end }}
  {{- end }}

  {{- /* Step 4: replicas (int, 可选): 仅在显式值 >= 0 时渲染, 缺省时由 K8s 默认为 1 (允许显式 0 表示缩容到零)
       约束: 显式值 < 0 时不渲染 (0 合法, 表示缩容到零; 负数非法)
       注: 兼容 Helm 4.2.2 fromYaml 对基本类型返回错误 map 的 BUG, 直接 atoi 解析 base.get 输出 */ -}}
  {{- $_replicasRaw := include "base.get" (list . "replicas" "int") | trim }}
  {{- if $_replicasRaw }}
    {{- $_replicas := atoi $_replicasRaw }}
    {{- if ge $_replicas 0 }}
      {{- include "base.field" (list "replicas" $_replicas "base.int") }}
    {{- end }}
  {{- end }}

  {{- /* Step 5: revisionHistoryLimit (int, 可选): 仅在显式值 >= 0 时渲染, 缺省时由 K8s 默认为 10
       约束: 显式值 < 0 时不渲染 (允许显式 0 表示不保留历史, 0 和负数中 0 合法, 负数非法)
       注: 兼容 Helm 4.2.2 fromYaml 对基本类型返回错误 map 的 BUG, 直接 atoi 解析 base.get 输出 */ -}}
  {{- $_revisionHistoryLimitRaw := include "base.get" (list . "revisionHistoryLimit" "int") | trim }}
  {{- if $_revisionHistoryLimitRaw }}
    {{- $_revisionHistoryLimit := atoi $_revisionHistoryLimitRaw }}
    {{- if ge $_revisionHistoryLimit 0 }}
      {{- include "base.field" (list "revisionHistoryLimit" $_revisionHistoryLimit "base.int") }}
    {{- end }}
  {{- end }}

  {{- /*
    Step 6: selector (object, 必填): 委托 definitions.labelSelector 渲染
    - 至少包括 matchLabels 字段, matchExpressions 字段可选
    - base.labels 合并到 selector.matchLabels 字段中 (入参上下文: .)
    - 若 selector.matchLabels 已存在则 mustMerge, 否则直接使用 base.labels
    - 必填项缺失或非 map 类型时立即中断并报错
    - 兼容 Helm 4.2.2 fromYaml 对非 map 输入返回错误 map 的 BUG, 委托 base.isFromYamlError 检测
  */ -}}
  {{- $_selectorRaw := include "base.get" (list . "selector") | trim }}
  {{- if or (not $_selectorRaw) (eq $_selectorRaw "null") }}
    {{- fail "[apps.deploymentSpec] selector: required field is missing or empty" }}
  {{- end }}

  {{- $selectorVal := $_selectorRaw | fromYaml }}
  {{- if eq (include "base.isFromYamlError" $selectorVal) "true" }}
    {{- fail "[apps.deploymentSpec] selector: must be map type" }}
  {{- end }}
  {{- if not (kindIs "map" $selectorVal) }}
    {{- fail "[apps.deploymentSpec] selector: must be map type" }}
  {{- end }}

  {{- $labels := include "base.labels" . | fromYaml }}
  {{- if and $labels (kindIs "map" $labels) }}
    {{- $_matchLabels := get $selectorVal "matchLabels" }}
    {{- if kindIs "map" $_matchLabels }}
      {{- $_matchLabels = mustMerge $_matchLabels $labels }}
    {{- else }}
      {{- $_matchLabels = $labels }}
    {{- end }}
    {{- $_ := set $selectorVal "matchLabels" $_matchLabels }}
  {{- end }}

  {{- $selector := include "definitions.labelSelector" $selectorVal | fromYaml }}
  {{- if $selector }}
    {{- include "base.field" (list "selector" $selector "base.map") }}
  {{- end }}

  {{- /*
    Step 7: strategy (string/object, 可选): 统一规整为 dict 后委托 apps.deploymentStrategy 渲染
    - string 类型: 通过正则 ^(Recreate|RollingUpdate)?(?:\s*(\d+\%?))?(?:\s+(\d+\%?))?$ 解析,
      提取 type, rollingUpdate.maxSurge, rollingUpdate.maxUnavailable 组装为 dict
    - object 类型: 原生定义, 原样保留为 dict
    - 规整后的 dict 统一通过 include 传递, 下层不再区分类型
    - 兼容 Helm 4.2.2 fromYaml 对非 map 输入返回错误 map 的 BUG, 委托 base.isFromYamlError 检测
    - mustRegexMatch 预校验整串匹配, regexReplaceAll 提取三个捕获组
    - 空字符串不写入 dict, 空 type 不渲染 strategy 整体
  */ -}}
  {{- $_strategyRaw := include "base.get" (list . "strategy") | trim }}
  {{- $strategyVal := dict }}

  {{- if and $_strategyRaw (ne $_strategyRaw "null") }}
    {{- $parsed := $_strategyRaw | fromYaml }}
    {{- if and $parsed (eq (include "base.isFromYamlError" $parsed) "false") (kindIs "map" $parsed) }}

      {{- $strategyVal = mustDeepCopy $parsed }}

    {{- else }}
      {{- $const := include "base.env" "" | fromYaml }}
      {{- $pattern := $const.APPS.DEPLOYMENT.STRATEGY }}
      {{- if mustRegexMatch $pattern $_strategyRaw }}
        {{- $type := regexReplaceAll $pattern $_strategyRaw "${1}" }}
        {{- $maxSurge := regexReplaceAll $pattern $_strategyRaw "${2}" }}
        {{- $maxUnavailable := regexReplaceAll $pattern $_strategyRaw "${3}" }}

        {{- if $type }}
          {{- $_ := set $strategyVal "type" $type }}
        {{- end }}

        {{- if or $maxSurge $maxUnavailable }}
          {{- $rollingUpdate := dict }}
          {{- if $maxSurge }}
            {{- $_ := set $rollingUpdate "maxSurge" $maxSurge }}
          {{- end }}
          {{- if $maxUnavailable }}
            {{- $_ := set $rollingUpdate "maxUnavailable" $maxUnavailable }}
          {{- end }}
          {{- $_ := set $strategyVal "rollingUpdate" $rollingUpdate }}
        {{- end }}
      {{- end }}
    {{- end }}
  {{- end }}

  {{- if $strategyVal }}
    {{- $strategy := include "apps.deploymentStrategy" $strategyVal | fromYaml }}
    {{- if $strategy }}
      {{- include "base.field" (list "strategy" $strategy "base.map") }}
    {{- end }}
  {{- end }}

  {{- /*
    Step 8: template (object, 必填): 委托 core.podTemplateSpec 渲染, 上下文透传 (.)
    - 必填项缺失或非 map 类型时立即中断并报错
    - 兼容 Helm 4.2.2 fromYaml 对非 map 输入返回错误 map 的 BUG, 委托 base.isFromYamlError 检测
  */ -}}
  {{- $_templateRaw := include "base.get" (list . "template") | trim }}
  {{- if or (not $_templateRaw) (eq $_templateRaw "null") }}
    {{- fail "[apps.deploymentSpec] template: required field is missing or empty" }}
  {{- end }}

  {{- $templateVal := $_templateRaw | fromYaml }}
  {{- if eq (include "base.isFromYamlError" $templateVal) "true" }}
    {{- fail "[apps.deploymentSpec] template: must be map type" }}
  {{- end }}
  {{- if not (kindIs "map" $templateVal) }}
    {{- fail "[apps.deploymentSpec] template: must be map type" }}
  {{- end }}

  {{- $template := include "core.podTemplateSpec" . | fromYaml }}
  {{- if $template }}
    {{- include "base.field" (list "template" $template "base.map") }}
  {{- end }}
{{- end -}}
