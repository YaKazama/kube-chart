{{- /*
  渲染 Kubernetes LabelSelector 字段片段。

  行为 (按 K8s API 规范字段顺序):
    - matchExpressions (array, 可选): 接受字符串简写或原生 LabelSelectorRequirement map，归一化后委托 definitions.labelSelectorRequirement；非法字符串、空集合或占位返回非法中断。
    - matchLabels (object, 必填): 直接渲染 string 键值；缺失或非 map 中断。

  边界:
    - 使用 base.get 读取字段，自动识别 matchExpressionsAlias、matchLabelsAlias；不识别 mExprs、mLabels。
    - 归一化项委托占位模板 definitions.labelSelectorRequirement；本 change 不创建该模板、文件或 define。
    - 只输出 matchExpressions、matchLabels，不输出 status。

  入参: 上下文 map，可包含以下字段:
    - matchExpressions      (LabelSelectorRequirement array, 可选)  字符串简写或原生 map
    - matchLabels           (object, 必填)  标签键值，值必须为 string
    - matchExpressionsAlias (LabelSelectorRequirement array, 可选)  内置别名
    - matchLabelsAlias      (object, 可选)  内置别名

  返回值: 可嵌入 selector 下的 LabelSelector YAML 字段片段；非法入参中断渲染。

  示例:
    {{- include "definitions.labelSelector" (dict "matchLabels" (dict "app" "web")) }}
*/ -}}
{{- define "definitions.labelSelector" -}}
  {{- $const := include "base.env" "" | fromYaml }}

  {{- /* matchExpressions（LabelSelectorRequirement array, 可选）: 字符串简写或原生 map 归一化后委托 definitions.labelSelectorRequirement。 */ -}}
  {{- $matchExpressionsVal := include "base.get" (list . "matchExpressions") | fromYamlArray }}
  {{- $matchExpressions := list }}
  {{- range $index, $_expression := $matchExpressionsVal }}
    {{- $key := "" }}
    {{- $operator := "" }}
    {{- $hasValues := false }}
    {{- $valuesRaw := list }}

    {{- if kindIs "string" $_expression }}
      {{- if mustRegexMatch $const.K8S.SELECTOR.EQUALITY_FOR_APPS $_expression }}
        {{- $key = mustRegexReplaceAll $const.K8S.SELECTOR.EQUALITY_FOR_APPS $_expression "${1}" | trim }}
        {{- $_operatorToken := mustRegexReplaceAll $const.K8S.SELECTOR.EQUALITY_FOR_APPS $_expression "${2}" | trim }}
        {{- $_value := mustRegexReplaceAll $const.K8S.SELECTOR.EQUALITY_FOR_APPS $_expression "${3}" | trim }}
        {{- $operator = "In" }}
        {{- if eq $_operatorToken "!=" }}
          {{- $operator = "NotIn" }}
        {{- end }}
        {{- $valuesRaw = list $_value }}
        {{- $hasValues = true }}

      {{- else if mustRegexMatch $const.K8S.SELECTOR.SET_FOR_APPS $_expression }}
        {{- $key = mustRegexReplaceAll $const.K8S.SELECTOR.SET_FOR_APPS $_expression "${1}" | trim }}
        {{- $_operatorToken := mustRegexReplaceAll $const.K8S.SELECTOR.SET_FOR_APPS $_expression "${2}" | trim | lower }}
        {{- $_values := mustRegexReplaceAll $const.K8S.SELECTOR.SET_FOR_APPS $_expression "${3}" | trim }}
        {{- if eq $_operatorToken "in" }}
          {{- $operator = "In" }}
        {{- else if eq $_operatorToken "notin" }}
          {{- $operator = "NotIn" }}
        {{- else }}
          {{- fail (printf "[definitions.labelSelector] matchExpressions[%d]: unsupported set operator '%s'" $index $_operatorToken) }}
        {{- end }}
        {{- $valuesRaw = list $_values }}
        {{- $hasValues = true }}

      {{- else if mustRegexMatch $const.K8S.SELECTOR.EXISTS_FOR_APPS $_expression }}
        {{- $key = trimPrefix "!" $_expression }}
        {{- if hasPrefix "!" $_expression }}
          {{- $operator = "DoesNotExist" }}
        {{- else }}
          {{- $operator = "Exists" }}
        {{- end }}

      {{- else }}
        {{- fail (printf "[definitions.labelSelector] matchExpressions[%d]: unsupported selector '%s'" $index $_expression) }}
      {{- end }}

    {{- else if kindIs "map" $_expression }}
      {{- if not (hasKey $_expression "key") }}
        {{- fail (printf "[definitions.labelSelector] matchExpressions[%d].key: required field is missing" $index) }}
      {{- end }}
      {{- $key = get $_expression "key" }}
      {{- if not (kindIs "string" $key) }}
        {{- fail (printf "[definitions.labelSelector] matchExpressions[%d].key: must be string type" $index) }}
      {{- end }}
      {{- $key = trim $key }}
      {{- if eq $key "" }}
        {{- fail (printf "[definitions.labelSelector] matchExpressions[%d].key: must not be empty" $index) }}
      {{- end }}

      {{- if not (hasKey $_expression "operator") }}
        {{- fail (printf "[definitions.labelSelector] matchExpressions[%d].operator: required field is missing" $index) }}
      {{- end }}
      {{- $_operatorRaw := get $_expression "operator" }}
      {{- if not (kindIs "string" $_operatorRaw) }}
        {{- fail (printf "[definitions.labelSelector] matchExpressions[%d].operator: must be string type" $index) }}
      {{- end }}
      {{- $_operatorToken := lower (trim $_operatorRaw) }}
      {{- if eq $_operatorToken "in" }}
        {{- $operator = "In" }}
      {{- else if eq $_operatorToken "notin" }}
        {{- $operator = "NotIn" }}
      {{- else if eq $_operatorToken "exists" }}
        {{- $operator = "Exists" }}
      {{- else if eq $_operatorToken "doesnotexist" }}
        {{- $operator = "DoesNotExist" }}
      {{- else }}
        {{- fail (printf "[definitions.labelSelector] matchExpressions[%d].operator: must be one of In, NotIn, Exists, DoesNotExist" $index) }}
      {{- end }}

      {{- if or (eq $operator "In") (eq $operator "NotIn") }}
        {{- if not (hasKey $_expression "values") }}
          {{- fail (printf "[definitions.labelSelector] matchExpressions[%d].values: required for %s" $index $operator) }}
        {{- end }}
        {{- $valuesRaw = get $_expression "values" }}
        {{- if not (kindIs "slice" $valuesRaw) }}
          {{- fail (printf "[definitions.labelSelector] matchExpressions[%d].values: must be array type" $index) }}
        {{- end }}
        {{- range $_value := $valuesRaw }}
          {{- if not (kindIs "string" $_value) }}
            {{- fail (printf "[definitions.labelSelector] matchExpressions[%d].values: items must be string type" $index) }}
          {{- end }}
        {{- end }}
        {{- $hasValues = true }}

      {{- else if hasKey $_expression "values" }}
        {{- $_values := get $_expression "values" }}
        {{- if kindIs "slice" $_values }}
          {{- if gt (len $_values) 0 }}
            {{- fail (printf "[definitions.labelSelector] matchExpressions[%d].values: must be empty for %s" $index $operator) }}
          {{- end }}
        {{- else if not (kindIs "invalid" $_values) }}
          {{- fail (printf "[definitions.labelSelector] matchExpressions[%d].values: must be array type for %s" $index $operator) }}
        {{- end }}
      {{- end }}

    {{- else }}
      {{- fail (printf "[definitions.labelSelector] matchExpressions[%d]: must be string or object type, got '%s'" $index (kindOf $_expression)) }}
    {{- end }}

    {{- $requirement := dict "key" $key "operator" $operator }}
    {{- if $hasValues }}
      {{- $_cleaned := include "base.slice.cleanup" (list $valuesRaw $const.SPLIT.COMMA) | fromYamlArray }}
      {{- if not $_cleaned }}
        {{- fail (printf "[definitions.labelSelector] matchExpressions[%d]: values must be non-empty" $index) }}
      {{- end }}
      {{- $_ := set $requirement "values" (toStrings $_cleaned) }}
    {{- end }}

    {{- $_rendered := include "definitions.labelSelectorRequirement" $requirement | fromYaml }}
    {{- if eq (include "base.isFromYamlError" $_rendered) "true" }}
      {{- fail (printf "[definitions.labelSelector] matchExpressions[%d]: definitions.labelSelectorRequirement returned invalid YAML" $index) }}
    {{- end }}
    {{- if empty $_rendered }}
      {{- fail (printf "[definitions.labelSelector] matchExpressions[%d]: definitions.labelSelectorRequirement returned empty output" $index) }}
    {{- end }}
    {{- $matchExpressions = mustAppend $matchExpressions $_rendered }}
  {{- end }}

  {{- if $matchExpressions }}
    {{- include "base.field" (list "matchExpressions" $matchExpressions "base.slice") }}
  {{- end }}

  {{- /* matchLabels（object, 必填）: 直接渲染 string 键值，内置别名由 base.get 处理。 */ -}}
  {{- $matchLabels := include "base.get" (list . "matchLabels") | fromYaml }}
  {{- if eq (include "base.isFromYamlError" $matchLabels) "true" }}
    {{- fail "[definitions.labelSelector] matchLabels: must be object type" }}
  {{- end }}
  {{- if empty $matchLabels }}
    {{- fail "[definitions.labelSelector] matchLabels: required field is missing or null" }}
  {{- end }}
  {{- range $key, $value := $matchLabels }}
    {{- if not (kindIs "string" $value) }}
      {{- fail (printf "[definitions.labelSelector] matchLabels.%s: must be string type" $key) }}
    {{- end }}
  {{- end }}
  {{- include "base.field" (list "matchLabels" $matchLabels "base.map") }}
{{- end }}
