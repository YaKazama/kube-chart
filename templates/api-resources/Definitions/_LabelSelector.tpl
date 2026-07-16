{{- /*
  渲染 Kubernetes LabelSelector。参考 https://kubernetes.io/docs/reference/kubernetes-api/definitions/label-selector-v1-meta/

  行为 (按 K8s API 规范字段顺序):
    - matchExpressions (array, 可选): 支持原生对象或字符串简写, 规整为 dict 后委托 definitions.labelSelectorRequirement, 末尾 mustUniq | mustCompact 去重去空。
    - matchLabels (object, 必填): 直接渲染标签键值对, 缺失或非 map 类型立即中断并报错。

  核心字段: dict, 包含 matchLabels 和可选 matchExpressions。

  返回值: LabelSelector YAML 对象。

  示例:
    {{- include "definitions.labelSelector" (dict "matchLabels" (dict "app" "api") "matchExpressions" (list "tier In (frontend,backend)")) }}
*/ -}}
{{- define "definitions.labelSelector" -}}
  {{- /*
    Step 1: matchExpressions (array, 可选): 支持原生对象或字符串简写, 规整为 dict 后委托 definitions.labelSelectorRequirement 渲染
    - 元素类型: map (原生对象) / string (简写, 通过 K8S.SELECTOR.EQUALITY0 / SET0 / SET_EXISTS 解析)
    - 列表字面量特征: "- " 开头 (非空) 或 "[]" (空), 借助 fromYamlArray 解析
    - 兼容 Helm 4.2.2 fromYamlArray 对非列表输入返回错误切片的 BUG, 委托 base.isFromYamlArrayError 检测
    - 末尾 mustUniq | mustCompact 去重去空
    - 解析前置声明 $expressionDict / $key / $operator / $values, 各分支用 = 赋值, 避免散落 :=
    - 原生 object 通过 pick 提取 K8s 规范字段, 防止外部注入额外字段
    - SET0 values 用 mustRegexSplit + mustAppend 手动拆分行, 保留 string 类型, 避免 base.slice.cleanup 自动把数字字符串转 int
  */ -}}
  {{- $_matchExpressionsRaw := include "base.get" (list . "matchExpressions") }}
  {{- $matchExpressions := list }}
  {{- if and $_matchExpressionsRaw (ne $_matchExpressionsRaw "null") }}
    {{- if not (or (hasPrefix "- " $_matchExpressionsRaw) (eq $_matchExpressionsRaw "[]")) }}
      {{- fail "[definitions.labelSelector] matchExpressions: must be array type" }}
    {{- end }}
    {{- $expressions := $_matchExpressionsRaw | fromYamlArray }}
    {{- if eq (include "base.isFromYamlArrayError" $expressions) "true" }}
      {{- fail "[definitions.labelSelector] matchExpressions: must be array type" }}
    {{- end }}

    {{- $const := include "base.env" "" | fromYaml }}
    {{- range $index, $expression := $expressions }}
      {{- $expressionDict := dict }}
      {{- $key := "" }}
      {{- $operator := "" }}
      {{- $values := list }}

      {{- if kindIs "map" $expression }}
        {{- $expressionDict = pick $expression "key" "operator" "values" }}
      {{- else if kindIs "string" $expression }}
        {{- if mustRegexMatch $const.K8S.SELECTOR.EQUALITY0 $expression }}
          {{- $key = mustRegexReplaceAll $const.K8S.SELECTOR.EQUALITY0 $expression "${1}" | trim }}
          {{- $values = list (mustRegexReplaceAll $const.K8S.SELECTOR.EQUALITY0 $expression "${3}" | trim) }}
          {{- $operator = "In" }}

          {{- $_operator := mustRegexReplaceAll $const.K8S.SELECTOR.EQUALITY0 $expression "${2}" | trim }}
          {{- if eq $_operator "!=" }}
            {{- $operator = "NotIn" }}
          {{- end }}
          {{- $expressionDict = dict "key" $key "operator" $operator "values" $values }}
        {{- else if mustRegexMatch $const.K8S.SELECTOR.SET0 $expression }}
          {{- $key = mustRegexReplaceAll $const.K8S.SELECTOR.SET0 $expression "${1}" | trim }}
          {{- $operator = "In" }}

          {{- $_operator := mustRegexReplaceAll $const.K8S.SELECTOR.SET0 $expression "${2}" | trim | lower }}
          {{- if eq $_operator "notin" }}
            {{- $operator = "NotIn" }}
          {{- end }}
          {{- $_valuesRaw := mustRegexReplaceAll $const.K8S.SELECTOR.SET0 $expression "${3}" | trim }}
          {{- range $value := mustRegexSplit $const.SPLIT.COMMA $_valuesRaw -1 }}
            {{- $value = $value | trim }}
            {{- if not $value }}
              {{- fail (printf "[definitions.labelSelector] matchExpressions[%d]: set selector contains an empty value" $index) }}
            {{- end }}
            {{- $values = mustAppend $values $value }}
          {{- end }}
          {{- $expressionDict = dict "key" $key "operator" $operator "values" ($values | mustUniq | mustCompact) }}
        {{- else if mustRegexMatch $const.K8S.SELECTOR.SET_EXISTS $expression }}
          {{- $key = mustRegexReplaceAll $const.K8S.SELECTOR.SET_EXISTS $expression "${2}" | trim }}
          {{- $operator = "Exists" }}

          {{- $_not := mustRegexReplaceAll $const.K8S.SELECTOR.SET_EXISTS $expression "${1}" | trim }}
          {{- if eq $_not "!" }}
            {{- $operator = "DoesNotExist" }}
          {{- end }}
          {{- $expressionDict = dict "key" $key "operator" $operator }}
        {{- else }}
          {{- fail (printf "[definitions.labelSelector] matchExpressions[%d]: unsupported selector '%s'" $index $expression) }}
        {{- end }}
      {{- else }}
        {{- fail (printf "[definitions.labelSelector] matchExpressions[%d]: must be string or object type" $index) }}
      {{- end }}

      {{- $rendered := include "definitions.labelSelectorRequirement" $expressionDict | fromYaml }}
      {{- if or (eq (include "base.isFromYamlError" $rendered) "true") (not $rendered) }}
        {{- fail (printf "[definitions.labelSelector] matchExpressions[%d]: rendered to empty or invalid object" $index) }}
      {{- end }}
      {{- $matchExpressions = mustAppend $matchExpressions $rendered }}
    {{- end }}

    {{- $matchExpressions = $matchExpressions | mustUniq | mustCompact }}

    {{- if $matchExpressions }}
      {{- include "base.field" (list "matchExpressions" $matchExpressions "base.slice") }}
    {{- end }}
  {{- end }}

  {{- /*
    Step 2: matchLabels (object, 必填): 原样渲染标签键值对
    - 必填项缺失或非 map 类型时立即中断并报错
    - 兼容 Helm 4.2.2 fromYaml 对非 map 输入返回错误 map 的 BUG, 委托 base.isFromYamlError 检测
  */ -}}
  {{- $_matchLabelsRaw := include "base.get" (list . "matchLabels") }}
  {{- if or (not $_matchLabelsRaw) (eq $_matchLabelsRaw "null") }}
    {{- fail "[definitions.labelSelector] matchLabels: required field is missing or empty" }}
  {{- end }}
  {{- $matchLabels := $_matchLabelsRaw | fromYaml }}
  {{- if or (eq (include "base.isFromYamlError" $matchLabels) "true") (not (kindIs "map" $matchLabels)) }}
    {{- fail "[definitions.labelSelector] matchLabels: must be object type" }}
  {{- end }}

  {{- include "base.field" (list "matchLabels" $matchLabels "base.map") }}
{{- end -}}
