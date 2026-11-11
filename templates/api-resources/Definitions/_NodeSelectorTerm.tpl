{{- /*
  渲染 Kubernetes NodeSelectorTerm 字段片段。

  行为 (按 K8s API 规范字段顺序):
    - matchExpressions (NodeSelectorRequirement array, 可选): string 条目或原生 map 条目归一化后逐条委托 definitions.nodeSelectorRequirement。
    - matchFields (NodeSelectorRequirement array, 可选): 与 matchExpressions 同一套归一化与校验规则，复用同一子模板。

  边界:
    - 使用 base.get 读取两个字段，自动识别 matchExpressionsAlias、matchFieldsAlias；无有效条目时不输出该字段，两个字段都无有效内容时返回空字符串。
    - 两个字段允许 string 条目与原生 map 条目混用，每个条目独立解析；null、空白字符串与空 map 条目被移除，归一化后的条目去重。
    - string 条目只识别三类形态：裸 <key> 与 !<key>、<key> (in|notin) (<value>[, <value>...])、<key> (!=|==|=|>|<) <value>；裸 key 归一化为 Exists，!key 归一化为 DoesNotExist，! 不得与运算符组合；无法解析时中断。
    - 条目主正则只做结构切分，key 取宽松 token 后由标签键语法校验；values 原文由独立正则限定为括号列表或单个不带空白、逗号与括号的 token，括号形式仅限 in、notin 两类 token。
    - key 按标签键语法校验：至多一个 /，名称段与前缀段分别按字符与长度约束校验。
    - values 在本层完成拆分、去空、去重、数值规范化与约束校验，子模板不再处理；In、NotIn 必须非空，Exists、DoesNotExist 必须为空，Gt、Lt 必须恰好一个整数。
    - 本模板主动产生的失败消息使用 [definitions.nodeSelectorTerm] 前缀并带字段名与条目下标。

  入参: 上下文 map，可包含以下字段:
    - matchExpressions      (string 与 NodeSelectorRequirement 混合 array, 可选) 选择表达式
    - matchFields           (string 与 NodeSelectorRequirement 混合 array, 可选) 字段选择表达式
    - matchExpressionsAlias (同上, 可选) 内置别名
    - matchFieldsAlias      (同上, 可选) 内置别名

  返回值: 可嵌入 selector.nodeSelectorTerms 单项的 NodeSelectorTerm YAML 字段片段；无有效内容时为空字符串，非法入参中断渲染。

  示例:
    {{- include "definitions.nodeSelectorTerm" (dict "matchExpressions" (list "c != d") "matchFields" (list "aa in (xx1, xx2)")) }}
*/ -}}
{{- define "definitions.nodeSelectorTerm" -}}
  {{- /* matchExpressions（NodeSelectorRequirement array, 可选）: string 简写与原生 map 条目归一化、校验、去重后委托 definitions.nodeSelectorRequirement，结果非空时按字段输出。 */ -}}
  {{- $_matchExpressionsRaw := include "definitions.nodeSelectorTerm.requirementList" (list . "matchExpressions") }}
  {{- if $_matchExpressionsRaw }}
    {{- include "base.field" (list "matchExpressions" (fromYamlArray $_matchExpressionsRaw) "base.slice") }}
  {{- end }}

  {{- /* matchFields（NodeSelectorRequirement array, 可选）: 同 matchExpressions。 */ -}}
  {{- $_matchFieldsRaw := include "definitions.nodeSelectorTerm.requirementList" (list . "matchFields") }}
  {{- if $_matchFieldsRaw }}
    {{- include "base.field" (list "matchFields" (fromYamlArray $_matchFieldsRaw) "base.slice") }}
  {{- end }}
{{- end }}

{{- /*
  归一化并渲染 NodeSelectorTerm 中的单个条目数组字段。

  行为: 经 base.get 取值并保留默认别名识别，非空时解析为 array；string 条目按主正则切出 !、key、运算符与 values 原文后归一化，原生 map 条目经 base.get 取值并把大小写不敏感运算符映射为六个规范枚举；空条目与空字段跳过，条目类型非法时中断；key 交由 base.labelKey 校验，values 与 operator 的适用关系在本层判定；归一化条目去重后逐项委托 definitions.nodeSelectorRequirement，返回值排除 YAML 解析错误。

  入参: list [上下文, 字段名]。

  边界: 只负责单个字段的取值、条目归一化、校验、去重与委托；不输出字段，也不处理另一个条目字段。

  返回值: 可 fromYamlArray 解析的已渲染条目 YAML 列表文本；字段缺失、无有效条目或解析为空时为空字符串。

  示例:
    {{- include "definitions.nodeSelectorTerm.requirementList" (list .Values.term "matchExpressions") }}
*/ -}}
{{- define "definitions.nodeSelectorTerm.requirementList" -}}
  {{- $const := include "base.env" "" | fromYaml }}
  {{- $root := index . 0 }}
  {{- $name := index . 1 }}

  {{- $_raw := include "base.get" (list $root $name) | trim }}
  {{- if $_raw }}
    {{- $_items := fromYamlArray $_raw }}
    {{- if eq (include "base.isFromYamlArrayError" $_items) "true" }}
      {{- fail (printf "[definitions.nodeSelectorTerm] %s: must be array type" $name) }}
    {{- end }}

    {{- $requirements := list }}
    {{- range $index, $_item := $_items }}
      {{- $skip := true }}
      {{- $key := "" }}
      {{- $operator := "" }}
      {{- $values := list }}

      {{- /* string 条目：主正则切出 !、key、运算符与 values 原文，values 形态与运算符类别的一致性由校验保证。 */ -}}
      {{- if kindIs "string" $_item }}
        {{- $_text := trim $_item }}
        {{- if $_text }}
          {{- if not (mustRegexMatch $const.K8S.SELECTOR.NODE_TERM_FOR_APPS $_text) }}
            {{- fail (printf "[definitions.nodeSelectorTerm] %s[%d]: unsupported selector '%s'" $name $index $_text) }}
          {{- end }}
          {{- $_bang := mustRegexReplaceAll $const.K8S.SELECTOR.NODE_TERM_FOR_APPS $_text "${1}" | trim }}
          {{- $key = mustRegexReplaceAll $const.K8S.SELECTOR.NODE_TERM_FOR_APPS $_text "${2}" | trim }}
          {{- $_operatorToken := mustRegexReplaceAll $const.K8S.SELECTOR.NODE_TERM_FOR_APPS $_text "${3}" | trim | lower }}
          {{- $_valueText := mustRegexReplaceAll $const.K8S.SELECTOR.NODE_TERM_FOR_APPS $_text "${4}" | trim }}
          {{- if and $_bang $_operatorToken }}
            {{- fail (printf "[definitions.nodeSelectorTerm] %s[%d]: '!' must not be combined with an operator" $name $index) }}
          {{- end }}

          {{- if $_operatorToken }}
            {{- /* 正则已限定 token 集合，in、=、== 落在默认值 In。 */ -}}
            {{- $operator = "In" }}
            {{- if or (eq $_operatorToken "notin") (eq $_operatorToken "!=") }}
              {{- $operator = "NotIn" }}
            {{- else if eq $_operatorToken ">" }}
              {{- $operator = "Gt" }}
            {{- else if eq $_operatorToken "<" }}
              {{- $operator = "Lt" }}
            {{- end }}

            {{- /* values 原文只允许括号列表或单个不带空白、逗号与括号的 token；括号形式仅限 in、notin 两类 token。 */ -}}
            {{- if not (mustRegexMatch $const.K8S.SELECTOR.NODE_TERM_VALUES_FOR_APPS $_valueText) }}
              {{- fail (printf "[definitions.nodeSelectorTerm] %s[%d].values: must be a parenthesized list or a single token without spaces, commas or parentheses" $name $index) }}
            {{- end }}
            {{- $_setOperator := or (eq $_operatorToken "in") (eq $_operatorToken "notin") }}
            {{- $_listText := $_valueText }}
            {{- if hasPrefix "(" $_valueText }}
              {{- if not $_setOperator }}
                {{- fail (printf "[definitions.nodeSelectorTerm] %s[%d].values: %s does not accept a parenthesized list" $name $index $operator) }}
              {{- end }}
              {{- $_listText = trimSuffix ")" (trimPrefix "(" $_valueText) }}
            {{- else if $_setOperator }}
              {{- fail (printf "[definitions.nodeSelectorTerm] %s[%d].values: %s requires a parenthesized list" $name $index $operator) }}
            {{- end }}
            {{- $values = toStrings (include "base.slice.cleanup" (list $_listText $const.SPLIT.COMMA) | fromYamlArray) }}
          {{- else if $_bang }}
            {{- $operator = "DoesNotExist" }}
          {{- else }}
            {{- $operator = "Exists" }}
          {{- end }}
          {{- $skip = false }}
        {{- end }}

      {{- /* 原生 map 条目：base.get 取值与别名识别，base.string.normalize 解码后把 operator 输入大小写不敏感地映射为六个规范枚举。 */ -}}
      {{- else if kindIs "map" $_item }}
        {{- if $_item }}
          {{- $key = include "base.string.normalize" (include "base.get" (list $_item "key")) | trim }}

          {{- $_operatorToken := lower (include "base.string.normalize" (include "base.get" (list $_item "operator")) | trim) }}
          {{- if eq $_operatorToken "in" }}
            {{- $operator = "In" }}
          {{- else if eq $_operatorToken "notin" }}
            {{- $operator = "NotIn" }}
          {{- else if eq $_operatorToken "gt" }}
            {{- $operator = "Gt" }}
          {{- else if eq $_operatorToken "lt" }}
            {{- $operator = "Lt" }}
          {{- else if eq $_operatorToken "exists" }}
            {{- $operator = "Exists" }}
          {{- else if eq $_operatorToken "doesnotexist" }}
            {{- $operator = "DoesNotExist" }}
          {{- else }}
            {{- fail (printf "[definitions.nodeSelectorTerm] %s[%d].operator: must be one of DoesNotExist, Exists, Gt, In, Lt, NotIn" $name $index) }}
          {{- end }}

          {{- $_valuesRaw := include "base.get" (list $_item "values") | fromYamlArray }}
          {{- if eq (include "base.isFromYamlArrayError" $_valuesRaw) "true" }}
            {{- fail (printf "[definitions.nodeSelectorTerm] %s[%d].values: must be array type" $name $index) }}
          {{- end }}
          {{- $values = toStrings (include "base.slice.cleanup" (list (mustWithout $_valuesRaw nil) $const.SPLIT.COMMA) | fromYamlArray) }}
          {{- $skip = false }}
        {{- end }}

      {{- else if not (kindIs "invalid" $_item) }}
        {{- fail (printf "[definitions.nodeSelectorTerm] %s[%d]: must be string or object type, got '%s'" $name $index (kindOf $_item)) }}
      {{- end }}

      {{- if not $skip }}
        {{- /* key（string, 必填）: 空值先按必填缺失中断，其余语法交由 base.labelKey 校验，失败消息使用本模板名与条目字段路径。 */ -}}
        {{- if eq $key "" }}
          {{- fail (printf "[definitions.nodeSelectorTerm] %s[%d].key: required field is missing or empty" $name $index) }}
        {{- end }}
        {{- $key = include "base.labelKey" (list $key "definitions.nodeSelectorTerm" (printf "%s[%d].key" $name $index)) }}

        {{- /* values（string array, 视 operator 可选）: In、NotIn 必须非空；Exists、DoesNotExist 必须为空；Gt、Lt 必须恰好一个整数。 */ -}}
        {{- if or (eq $operator "In") (eq $operator "NotIn") }}
          {{- if not $values }}
            {{- fail (printf "[definitions.nodeSelectorTerm] %s[%d].values: required for %s" $name $index $operator) }}
          {{- end }}
        {{- else if or (eq $operator "Gt") (eq $operator "Lt") }}
          {{- if ne (len $values) 1 }}
            {{- fail (printf "[definitions.nodeSelectorTerm] %s[%d].values: %s requires exactly one value" $name $index $operator) }}
          {{- end }}
          {{- if not (mustRegexMatch $const.TYPES.INT (first $values)) }}
            {{- fail (printf "[definitions.nodeSelectorTerm] %s[%d].values: %s requires an integer value" $name $index $operator) }}
          {{- end }}
        {{- else if $values }}
          {{- fail (printf "[definitions.nodeSelectorTerm] %s[%d].values: must be empty for %s" $name $index $operator) }}
        {{- end }}

        {{- $requirement := dict "key" $key "operator" $operator }}
        {{- if $values }}
          {{- $_ := set $requirement "values" $values }}
        {{- end }}
        {{- $requirements = mustAppend $requirements $requirement }}
      {{- end }}
    {{- end }}

    {{- if $requirements }}
      {{- /* 去重后逐条委托子模板，返回值排除 YAML 解析错误后暂存；本层不再校验子模板内部字段。 */ -}}
      {{- $rendered := list }}
      {{- range $_requirement := mustUniq $requirements }}
        {{- $_itemRendered := include "definitions.nodeSelectorRequirement" $_requirement | fromYaml }}
        {{- if eq (include "base.isFromYamlError" $_itemRendered) "true" }}
          {{- fail (printf "[definitions.nodeSelectorTerm] %s: definitions.nodeSelectorRequirement returned invalid YAML" $name) }}
        {{- end }}
        {{- $rendered = mustAppend $rendered $_itemRendered }}
      {{- end }}
      {{- toYamlPretty $rendered }}
    {{- end }}
  {{- end }}
{{- end }}
