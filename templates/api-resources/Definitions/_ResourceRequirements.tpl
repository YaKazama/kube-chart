{{- /*
  渲染 Kubernetes ResourceRequirements 字段片段。

  行为 (按 K8s API 规范字段顺序):
    - claims (ResourceClaim array, 可选): 数组元素可为 string 简写或原生 map，归一化为 map 后逐项委托 definitions.resourceClaim，回收非空结果。
    - limits (object, 可选): 原生 map 或位置简写，委托 definitions.resourceRequirements.field 归一化、校验并渲染。
    - requests (object, 可选): 同 limits。

  边界:
    - 三个字段均为可选；全部无有效输出时本模板输出空内容，不输出 resources 父键。
    - 只识别 claims、limits、requests 三个规范键；base.get 默认开启别名识别，因此 claimsAlias、limitsAlias、requestsAlias 隐式生效。
    - 上下文含 _kind=PodSpec 表示 Pod 级调用：claims 静默忽略，资源键收窄为 cpu、memory、hugepages-<size>，ephemeral-storage 静默丢弃。
    - 巨页（hugepages）处理说明: 使用 `cat /proc/meminfo | grep -i huge` 查看宿主机的 Hugepagesize 与 HugePages_Total，按 Hugepagesize 决定 size，按 HugePages_Total 决定 max = size × 页数；size 与 max 必须同单位且成整数倍。
    - 除上述字段及其同级别名以外的入参字段静默忽略；不输出 status。

  入参: 上下文 map，由 core.podSpec 或容器模板透传，可包含以下字段:
    - _kind    (string, 可选)              调用方标识；PodSpec 表示 Pod 级 resources
    - claims   (ResourceClaim array, 可选) 容器使用的资源声明
    - limits   (object, 可选)              资源上限
    - requests (object, 可选)              资源下限

  返回值: 可嵌入 spec 或容器下的 ResourceRequirements YAML 字段片段；无有效内容时为空。

  示例:
    {{- include "definitions.resourceRequirements" (dict "limits" (dict "cpu" "500m" "memory" "512Mi")) }}
*/ -}}
{{- define "definitions.resourceRequirements" -}}
  {{- $const := include "base.env" "" | fromYaml }}

  {{- /* _kind（string, 可选）: 由 core.podSpec 写入 PodSpec 标记，用于收窄资源键范围并忽略 claims。 */ -}}
  {{- $kind := include "base.get" (list . "_kind") | trim }}

  {{- /* claims（ResourceClaim array, 可选）: string 简写按空格和逗号拆分为 name、request，map 项原样委托；Pod 级调用直接忽略。 */ -}}
  {{- $_claimsRaw := include "base.get" (list . "claims") | trim }}
  {{- if and $_claimsRaw (ne $kind "PodSpec") }}
    {{- $_claims := fromYamlArray $_claimsRaw }}
    {{- if eq (include "base.isFromYamlArrayError" $_claims) "true" }}
      {{- fail "[definitions.resourceRequirements] claims: must be array type" }}
    {{- end }}

    {{- $rendered := list }}
    {{- range $index, $_claim := $_claims }}
      {{- if kindIs "string" $_claim }}
        {{- $_parts := mustCompact (mustRegexSplit $const.SPLIT.SPACE_COMMA (trim $_claim) -1) }}
        {{- if or (eq (len $_parts) 0) (gt (len $_parts) 2) }}
          {{- fail (printf "[definitions.resourceRequirements] claims[%d]: must contain one or two segments, got '%s'" $index $_claim) }}
        {{- end }}
        {{- $_claim = dict "name" (toString (index $_parts 0)) }}
        {{- if ge (len $_parts) 2 }}
          {{- $_ := set $_claim "request" (toString (index $_parts 1)) }}
        {{- end }}

      {{- else if not (kindIs "map" $_claim) }}
        {{- fail (printf "[definitions.resourceRequirements] claims[%d]: must be string or map type, got '%s'" $index (kindOf $_claim)) }}
      {{- end }}

      {{- /* 委托子模板: 上下文恒为 map；返回空或非法 YAML 时剔除该项，由回收结果决定字段是否输出。 */ -}}
      {{- $_claimRendered := include "definitions.resourceClaim" $_claim | fromYaml }}
      {{- if and (ne (include "base.isFromYamlError" $_claimRendered) "true") $_claimRendered }}
        {{- $rendered = mustAppend $rendered $_claimRendered }}
      {{- end }}
    {{- end }}

    {{- if $rendered }}
      {{- include "base.field" (list "claims" $rendered "base.slice") }}
    {{- end }}
  {{- end }}

  {{- /* limits（object, 可选）: 整个 resources 上下文由父级透传，取值、归一化与渲染全部委托 definitions.resourceRequirements.field。 */ -}}
  {{- include "definitions.resourceRequirements.field" (dict "field" "limits" "raw" (include "base.get" (list . "limits")) "kind" $kind) }}

  {{- /* requests（object, 可选）: 同 limits。 */ -}}
  {{- include "definitions.resourceRequirements.field" (dict "field" "requests" "raw" (include "base.get" (list . "requests")) "kind" $kind) }}
{{- end }}


{{- /*
  渲染单个 CPU/Memory 资源字段（limits 或 requests）。

  行为:
    - 取值支持原生 map 与位置简写两种形态；简写按 `[cpu] [memory] [ephemeral-storage] ([size] [max])` 位置顺序解析。
    - 先剥离括注得到 hugepages-size 与 hugepages-max，再按空格和逗号拆分外层位置；`""`、`''` 与 `0` 分段视为未设置。
    - 两种形态归一化为同一资源 map 后共用白名单、零值与量值校验，再以 base.field + base.map 输出。

  边界:
    - 只输出传入的单个字段；白名单为 cpu、memory、ephemeral-storage、hugepages-<size>，Pod 级调用剔除 ephemeral-storage，白名单外的键静默丢弃。
    - 巨页（hugepages）处理说明: 使用 `cat /proc/meminfo | grep -i huge` 查看宿主机的 Hugepagesize 与 HugePages_Total，按 Hugepagesize 决定 size，按 HugePages_Total 决定 max = size × 页数；校验时统一换算为字节数，渲染时保持原样。
    - 括注最多一个且必须成对，内含 size 与 max 两项；外层位置超过 3 个、括注数不为 1、括注内容不是 2 项时中断。
    - 简写先由 base.string.normalize 完整解码，因此 YAML 外层引号已被移除；本模板不再按引号剥离任何值，字面 `""` 与 `''` 作为等价占位按位置剔除。
    - 输入既不是 map 也不是字符串简写时由 base.string.normalize 中断；失败消息使用本模板前缀并携带字段路径。
    - 本模板不实现 claims，也不输出 status。

  入参: 上下文 map，恒含以下字段:
    - field (string, 必填) 字段名，limits 或 requests，仅用于渲染键名与失败路径
    - raw   (string, 可选) base.get 返回的原始 YAML 字符串
    - kind  (string, 可选) 调用方标识，PodSpec 表示 Pod 级 resources

  返回值: 可嵌入 ResourceRequirements 的单个字段 YAML 片段；无有效内容或原始取值为空时输出空字符串。

  示例:
    {{- include "definitions.resourceRequirements.field" (dict "field" "limits" "raw" "500m 512Mi" "kind" "") }}
*/ -}}
{{- define "definitions.resourceRequirements.field" -}}
  {{- $const := include "base.env" "" | fromYaml }}
  {{- $factors := dict "Ki" 1024 "Mi" 1048576 "Gi" 1073741824 "Ti" 1099511627776 "Pi" 1125899906842624 "Ei" 1152921504606846976 }}
  {{- $field := .field }}
  {{- $kind := .kind }}
  {{- $_raw := trim .raw }}

  {{- if $_raw }}
    {{- $pairs := dict }}
    {{- $_parsed := $_raw | fromYaml }}
    {{- if eq (include "base.isFromYamlError" $_parsed) "true" }}
      {{- /* 位置简写: 先剥离唯一的括注，再按位置拆分；占位与未提供的位置均不产生键。 */ -}}
      {{- $text := include "base.string.normalize" $_raw | trim }}
      {{- $_groups := mustRegexFindAll $const.K8S.RESOURCE.HUGE_PAGES_PAIR $text -1 }}
      {{- if gt (len $_groups) 1 }}
        {{- fail (printf "[definitions.resourceRequirements.field] %s: at most one hugepages group is allowed" $field) }}
      {{- end }}

      {{- $slots := $text }}
      {{- if $_groups }}
        {{- $_group := index $_groups 0 }}
        {{- $slots = mustRegexReplaceAllLiteral $const.K8S.RESOURCE.HUGE_PAGES_PAIR $text "" | trim }}
        {{- $_inner := mustRegexSplit $const.SPLIT.SPACE_COMMA (trimSuffix ")" (trimPrefix "(" $_group)) -1 }}
        {{- if ne (len $_inner) 2 }}
          {{- fail (printf "[definitions.resourceRequirements.field] %s: hugepages group must contain size and max" $field) }}
        {{- end }}
        {{- $_ := set $pairs (printf "hugepages-%s" (index $_inner 0)) (index $_inner 1) }}
      {{- end }}

      {{- /* 字面 "" 与 '' 占位占据位置但不产生键；0 占位保留到统一零值判断阶段剔除。 */ -}}
      {{- $_slots := mustRegexSplit $const.SPLIT.SPACE_COMMA $slots -1 }}
      {{- if gt (len $_slots) 3 }}
        {{- fail (printf "[definitions.resourceRequirements.field] %s: at most three positional segments allowed, got '%d'" $field (len $_slots)) }}
      {{- end }}
      {{- $_names := list "cpu" "memory" "ephemeral-storage" }}
      {{- range $index, $_slot := $_slots }}
        {{- if not (mustHas $_slot (list "\"\"" "''")) }}
          {{- $_ := set $pairs (index $_names $index) $_slot }}
        {{- end }}
      {{- end }}

    {{- else }}
      {{- $pairs = $_parsed }}
    {{- end }}

    {{- /* 白名单筛选、零值剔除、量值校验与归一化: 两种形态共用同一条路径。 */ -}}
    {{- $resources := dict }}
    {{- range $key, $_value := $pairs }}
      {{- $_allowed := has $key (list "cpu" "memory" "ephemeral-storage") }}
      {{- if eq $kind "PodSpec" }}
        {{- $_allowed = has $key (list "cpu" "memory") }}
      {{- end }}

      {{- if or $_allowed (hasPrefix "hugepages-" $key) }}
        {{- $_text := toString $_value | trim }}

        {{- /* 数值或字符串 0 视为未设置，先于其他校验剔除。 */ -}}
        {{- if ne $_text "0" }}
          {{- if eq $key "cpu" }}
            {{- if not (mustRegexMatch $const.K8S.RESOURCE.CPU $_text) }}
              {{- fail (printf "[definitions.resourceRequirements.field] %s.cpu: must be integer or up to three decimal cores, or integer millicores, got '%s'" $field $_text) }}
            {{- end }}
            {{- $_intPart := mustRegexReplaceAll $const.K8S.RESOURCE.CPU $_text "$1" }}
            {{- $_fraction := mustRegexReplaceAll $const.K8S.RESOURCE.CPU $_text "$2" }}
            {{- $_suffix := mustRegexReplaceAll $const.K8S.RESOURCE.CPU $_text "$3" }}
            {{- if and (eq $_suffix "m") $_fraction }}
              {{- fail (printf "[definitions.resourceRequirements.field] %s.cpu: millicores must be integer, got '%s'" $field $_text) }}
            {{- end }}

            {{- $_millicores := 0 }}
            {{- if eq $_suffix "m" }}
              {{- $_millicores = atoi $_intPart }}
            {{- else }}
              {{- $_millicores = int (mulf (float64 (printf "%s%s" $_intPart $_fraction)) 1000) }}
            {{- end }}

            {{- /* 换算为 0 毫核的整数形式同样视为未设置；不足 1m 的其余值中断。 */ -}}
            {{- if ne $_millicores 0 }}
              {{- if lt $_millicores 1 }}
                {{- fail (printf "[definitions.resourceRequirements.field] %s.cpu: must not be less than 1m, got '%s'" $field $_text) }}
              {{- end }}
              {{- if $_fraction }}
                {{- $_ := set $resources "cpu" (printf "%dm" $_millicores) }}
              {{- else if eq $_suffix "m" }}
                {{- $_ := set $resources "cpu" $_text }}
              {{- else }}
                {{- $_ := set $resources "cpu" (atoi $_text) }}
              {{- end }}
            {{- end }}

          {{- else if hasPrefix "hugepages-" $key }}
            {{- $_size := trimPrefix "hugepages-" $key }}
            {{- if not (mustRegexMatch $const.K8S.RESOURCE.HUGE_PAGES_QUANTITY $_size) }}
              {{- fail (printf "[definitions.resourceRequirements.field] %s.%s: size must be integer with optional binary unit" $field $key) }}
            {{- end }}
            {{- if not (mustRegexMatch $const.K8S.RESOURCE.HUGE_PAGES_QUANTITY $_text) }}
              {{- fail (printf "[definitions.resourceRequirements.field] %s.%s: value must be integer with optional binary unit, got '%s'" $field $key $_text) }}
            {{- end }}

            {{- /* 单位必须相同；换算为字节数后校验 max 更大且为 size 的整数倍，渲染保持原值。 */ -}}
            {{- $_sizeUnit := mustRegexReplaceAll $const.K8S.RESOURCE.HUGE_PAGES_QUANTITY $_size "$2" }}
            {{- $_maxUnit := mustRegexReplaceAll $const.K8S.RESOURCE.HUGE_PAGES_QUANTITY $_text "$2" }}
            {{- if ne $_sizeUnit $_maxUnit }}
              {{- fail (printf "[definitions.resourceRequirements.field] %s.%s: size and max must use the same unit" $field $key) }}
            {{- end }}
            {{- $_factor := 1 }}
            {{- if $_sizeUnit }}
              {{- $_factor = get $factors $_sizeUnit }}
            {{- end }}
            {{- $_sizeBytes := mul (atoi (mustRegexReplaceAll $const.K8S.RESOURCE.HUGE_PAGES_QUANTITY $_size "$1")) $_factor }}
            {{- $_maxBytes := mul (atoi (mustRegexReplaceAll $const.K8S.RESOURCE.HUGE_PAGES_QUANTITY $_text "$1")) $_factor }}
            {{- if le $_maxBytes $_sizeBytes }}
              {{- fail (printf "[definitions.resourceRequirements.field] %s.%s: max must be greater than size" $field $key) }}
            {{- end }}
            {{- if ne (mod $_maxBytes $_sizeBytes) 0 }}
              {{- fail (printf "[definitions.resourceRequirements.field] %s.%s: max must be a multiple of size" $field $key) }}
            {{- end }}
            {{- $_ := include "base.quantity" $_text }}
            {{- $_ := set $resources $key $_text }}

          {{- else }}
            {{- $_ := include "base.quantity" $_text }}
            {{- $_ := set $resources $key $_value }}
          {{- end }}
        {{- end }}
      {{- end }}
    {{- end }}

    {{- if $resources }}
      {{- include "base.field" (list $field $resources "base.map") }}
    {{- end }}
  {{- end }}
{{- end }}
