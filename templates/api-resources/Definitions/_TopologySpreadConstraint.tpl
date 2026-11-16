{{- /*
  渲染 Kubernetes TopologySpreadConstraint 字段片段。

  行为 (按 K8s API 规范字段顺序):
    - labelSelector      (LabelSelector, 可选): 非空 map 时委托 definitions.labelSelector 渲染，本模板不解析其内部字段。
    - matchLabelKeys     (string array, 可选): 逐项按 string 校验，再拆分、剔除空项、去重后输出；labelSelector 未设置时不得提供。
    - maxSkew            (integer, 必填): 校验为正整数后按整数输出，0 视为非法。
    - minDomains         (integer, 可选): 提供时校验为正整数后按整数输出。
    - nodeAffinityPolicy (string, 可选): 非空时按 Honor、Ignore 枚举校验后以带引号标量输出。
    - nodeTaintsPolicy   (string, 可选): 同 nodeAffinityPolicy。
    - topologyKey        (string, 必填): 按标签键语法校验后原样输出。
    - whenUnsatisfiable  (string, 必填): 按 DoNotSchedule、ScheduleAnyway 枚举校验后以带引号标量输出。

  边界:
    - 只输出当前层字段，不输出 topologySpreadConstraints 父键、apiVersion 或 kind；required 字段保证模板恒有输出。
    - 字段按 API 顺序逐字段完成取值、校验与输出闭环后再处理下一字段；matchLabelKeys 依赖 labelSelector，故在同一闭环内完成该依赖校验。
    - 字符串字段缺失、为 null、为空字符串或只含空白时按未提供处理，跳过输出。
    - 字符串字段不是 string 时由 base.string.normalize 中断，不做类型归一化。
    - 枚举比较大小写敏感，donotschedule、honor 等非精确匹配由 base.field 中断并给出合法范围。
    - maxSkew、minDomains 只接受原生整数；带引号文本经 base.get 序列化后由 base.int 中断。
    - topologyKey 语法非法时由 base.labelKey 中断，失败消息携带本模板名与字段路径。
    - labelSelector 解析失败或不是 map 时中断；解析后为空 map 视为未提供，既不输出也不满足 matchLabelKeys 的依赖。
    - matchLabelKeys 元素不是 string 时中断；空字符串与纯空白元素被剔除，去重保留首次出现的位置。
    - base.get 默认开启别名识别，因此各字段同级 <字段>Alias 隐式生效；除上述字段及其同级别名以外的入参字段静默忽略，不输出 status。

  入参: 上下文 map，可包含以下字段:
    - labelSelector      (LabelSelector, 可选)  匹配的 Pod 标签选择器
    - matchLabelKeys     (string array, 可选)   参与分布计算的 Pod 标签键
    - maxSkew            (integer, 必填)        允许的最大分布偏差，必须大于 0
    - minDomains         (integer, 可选)        最小可用域数量，必须大于 0
    - nodeAffinityPolicy (string, 可选)         nodeAffinity、nodeSelector 的处理策略
    - nodeTaintsPolicy   (string, 可选)         节点污点的处理策略
    - topologyKey        (string, 必填)         拓扑域的节点标签键
    - whenUnsatisfiable  (string, 必填)         不满足约束时的调度行为

  返回值: 可嵌入 topologySpreadConstraints 元素下的 TopologySpreadConstraint YAML 字段片段。

  示例:
    {{- include "definitions.topologySpreadConstraint" (dict "maxSkew" 1 "topologyKey" "topology.kubernetes.io/zone" "whenUnsatisfiable" "DoNotSchedule") }}
      // maxSkew: 1
      // topologyKey: topology.kubernetes.io/zone
      // whenUnsatisfiable: "DoNotSchedule"
*/ -}}
{{- define "definitions.topologySpreadConstraint" -}}
  {{- $const := include "base.env" "" | fromYaml }}

  {{- /* labelSelector（LabelSelector, 可选）: 解析失败中断；空 map 视为未提供；非空时整体透传 definitions.labelSelector，回收非空结果后以 base.map 输出。 */ -}}
  {{- $labelSelector := dict }}
  {{- $_labelSelectorRaw := include "base.get" (list . "labelSelector") | trim }}
  {{- if $_labelSelectorRaw }}
    {{- $_parsed := $_labelSelectorRaw | fromYaml }}
    {{- if eq (include "base.isFromYamlError" $_parsed) "true" }}
      {{- fail "[definitions.topologySpreadConstraint] labelSelector: must be object type" }}
    {{- end }}
    {{- if $_parsed }}
      {{- $_rendered := include "definitions.labelSelector" $_parsed | fromYaml }}
      {{- if eq (include "base.isFromYamlError" $_rendered) "true" }}
        {{- fail "[definitions.topologySpreadConstraint] labelSelector: definitions.labelSelector returned invalid YAML" }}
      {{- end }}
      {{- $labelSelector = $_rendered }}
      {{- include "base.field" (list "labelSelector" $labelSelector "base.map") }}
    {{- end }}
  {{- end }}

  {{- /* matchLabelKeys（string array, 可选）: 非 array 中断；先逐项做 string 门禁，再拆分、剔除空项并去重；结果非空时要求 labelSelector 已设置，随后以 base.slice 输出。 */ -}}
  {{- $_matchLabelKeysRaw := include "base.get" (list . "matchLabelKeys") | trim }}
  {{- if $_matchLabelKeysRaw }}
    {{- $_matchLabelKeysArr := $_matchLabelKeysRaw | fromYamlArray }}
    {{- if eq (include "base.isFromYamlArrayError" $_matchLabelKeysArr) "true" }}
      {{- fail "[definitions.topologySpreadConstraint] matchLabelKeys: must be array type" }}
    {{- end }}
    {{- range $_item := $_matchLabelKeysArr }}
      {{- if not (kindIs "string" $_item) }}
        {{- fail (printf "[definitions.topologySpreadConstraint] matchLabelKeys: each item must be string type, got '%s'" (kindOf $_item)) }}
      {{- end }}
    {{- end }}
    {{- $matchLabelKeys := toStrings (include "base.slice.cleanup" (list $_matchLabelKeysArr $const.SPLIT.SPACE_COMMA) | fromYamlArray) }}
    {{- if $matchLabelKeys }}
      {{- if not $labelSelector }}
        {{- fail "[definitions.topologySpreadConstraint] matchLabelKeys: cannot be set when labelSelector is not set" }}
      {{- end }}
      {{- include "base.field" (list "matchLabelKeys" $matchLabelKeys "base.slice") }}
    {{- end }}
  {{- end }}

  {{- /* maxSkew（integer, 必填）: 必填取值后由 base.int 完成整数门禁，再由 base.int.range 拒绝小于 1 的取值，最后按整数输出。 */ -}}
  {{- $maxSkew := int (include "base.int.range" (list (int (include "base.int" (include "base.get" (list . "maxSkew" "" "" true)))) 1)) }}
  {{- include "base.field" (list "maxSkew" $maxSkew "base.int") }}

  {{- /* minDomains（integer, 可选）: 取值非空才校验，类型门禁与大于 0 的下限校验同 maxSkew，随后按整数输出。 */ -}}
  {{- $_minDomainsRaw := include "base.get" (list . "minDomains") | trim }}
  {{- if $_minDomainsRaw }}
    {{- $minDomains := int (include "base.int.range" (list (int (include "base.int" $_minDomainsRaw)) 1)) }}
    {{- include "base.field" (list "minDomains" $minDomains "base.int") }}
  {{- end }}

  {{- /* nodeAffinityPolicy（string, 可选）: 归一后非空时按 Honor、Ignore 枚举校验并以带引号标量输出。 */ -}}
  {{- $nodeAffinityPolicy := include "base.string.normalize" (include "base.get" (list . "nodeAffinityPolicy")) | trim }}
  {{- if $nodeAffinityPolicy }}
    {{- include "base.field" (list "nodeAffinityPolicy" $nodeAffinityPolicy "quote" (list "Honor" "Ignore")) }}
  {{- end }}

  {{- /* nodeTaintsPolicy（string, 可选）: 归一后非空时按 Honor、Ignore 枚举校验并以带引号标量输出。 */ -}}
  {{- $nodeTaintsPolicy := include "base.string.normalize" (include "base.get" (list . "nodeTaintsPolicy")) | trim }}
  {{- if $nodeTaintsPolicy }}
    {{- include "base.field" (list "nodeTaintsPolicy" $nodeTaintsPolicy "quote" (list "Honor" "Ignore")) }}
  {{- end }}

  {{- /* topologyKey（string, 必填）: 必填取值并解码，归一后为空时中断，非空时按标签键语法校验后原样输出。 */ -}}
  {{- $topologyKey := include "base.string.normalize" (include "base.get" (list . "topologyKey" "" "" true)) | trim }}
  {{- if not $topologyKey }}
    {{- fail "[definitions.topologySpreadConstraint] topologyKey: required field is missing or empty" }}
  {{- end }}
  {{- include "base.field" (list "topologyKey" (include "base.labelKey" (list $topologyKey "definitions.topologySpreadConstraint" "topologyKey")) "base.rawString") }}

  {{- /* whenUnsatisfiable（string, 必填）: 必填取值并解码，归一后为空时中断，非空时按 DoNotSchedule、ScheduleAnyway 枚举校验并以带引号标量输出。 */ -}}
  {{- $whenUnsatisfiable := include "base.string.normalize" (include "base.get" (list . "whenUnsatisfiable" "" "" true)) | trim }}
  {{- if not $whenUnsatisfiable }}
    {{- fail "[definitions.topologySpreadConstraint] whenUnsatisfiable: required field is missing or empty" }}
  {{- end }}
  {{- include "base.field" (list "whenUnsatisfiable" $whenUnsatisfiable "quote" (list "DoNotSchedule" "ScheduleAnyway")) }}
{{- end }}
