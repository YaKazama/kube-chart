{{- /*
  渲染 Kubernetes PodResourceClaim 字段片段。

  行为 (按 K8s API 规范字段顺序):
    - name (string, 必填): 经 base.get 必填取值，还原 YAML 标量类型确认 string 后剥离 YAML 标量引号并 trim；为空或仅空白时中断，非空时以带引号标量输出。
    - resourceClaimName (string, 可选): 经 base.get 取值，还原 YAML 标量类型确认 string 后剥离 YAML 标量引号并 trim；归一化为空时视为未设置。
    - resourceClaimTemplateName (string, 可选): 同 resourceClaimName。
    - 两个引用字段恰有一个生效：二者同时未设置或同时设置时中断。

  边界:
    - 只输出 name 与恰一个引用字段，不包含父级键；resourceClaims 数组的循环、字符串简写拆分、条目合并与去重由调用方负责。
    - base.get 默认开启别名识别，因此 nameAlias、resourceClaimNameAlias、resourceClaimTemplateNameAlias 隐式生效，本模板不额外实现别名映射。
    - name 缺失、为 null 或空字符串时由 base.get 必填校验中断；归一化后为空时以本模板前缀中断。
    - 任一字段存在但不是 string 时以本模板前缀中断；引用字段归一化为空时按未设置处理。
    - 不校验引用字段的名称格式；除三个字段及其同级别名以外的入参字段静默忽略；不输出 status、apiVersion、kind。

  入参: 上下文 map，由父级传入单个 resourceClaim 描述，可包含以下字段:
    - name                      (string, 必填) 该资源声明在 Pod 内的唯一名称
    - resourceClaimName         (string, 可选) 同命名空间内的 ResourceClaim 名称
    - resourceClaimTemplateName (string, 可选) 同命名空间内的 ResourceClaimTemplate 名称

  返回值: 可嵌入 resourceClaims 数组元素的 PodResourceClaim YAML 字段片段，恒含 name 与恰一个引用字段。

  示例:
    {{- include "definitions.podResourceClaim" (dict "name" "gpu" "resourceClaimName" "shared-gpu") }}
*/ -}}
{{- define "definitions.podResourceClaim" -}}
  {{- $const := include "base.env" "" | fromYaml }}

  {{- /* name（string, 必填）: base.get 承担必填取值与别名识别；先还原标量类型确认 string，再剥离 YAML 标量引号并 trim，仅空白等同未设置。 */ -}}
  {{- $_nameRaw := include "base.get" (list . "name" "" "" true) | trim }}
  {{- $name := "" }}
  {{- if $_nameRaw }}
    {{- /* 类型判定必须在去引号之前: 布尔与数值经 base.get 会序列化为同形文本，'"on"' 保留引号时才恢复为 string。 */ -}}
    {{- if not (kindIs "string" (fromYaml (printf "v: %s" $_nameRaw)).v) }}
      {{- fail (printf "[definitions.podResourceClaim] name: must be string type, got '%s'" $_nameRaw) }}
    {{- end }}
    {{- $name = mustRegexReplaceAll $const.SYS.YAML_QUOTED $_nameRaw "$1" | trim }}
  {{- end }}
  {{- if not $name }}
    {{- fail "[definitions.podResourceClaim] name: required field must not be blank" }}
  {{- end }}

  {{- /* resourceClaimName（string, 可选）: 还原标量类型确认 string 后剥离 YAML 标量引号并 trim，归一化为空时视为未设置。 */ -}}
  {{- $_resourceClaimNameRaw := include "base.get" (list . "resourceClaimName") | trim }}
  {{- $resourceClaimName := "" }}
  {{- if $_resourceClaimNameRaw }}
    {{- if not (kindIs "string" (fromYaml (printf "v: %s" $_resourceClaimNameRaw)).v) }}
      {{- fail (printf "[definitions.podResourceClaim] resourceClaimName: must be string type, got '%s'" $_resourceClaimNameRaw) }}
    {{- end }}
    {{- $resourceClaimName = mustRegexReplaceAll $const.SYS.YAML_QUOTED $_resourceClaimNameRaw "$1" | trim }}
  {{- end }}

  {{- /* resourceClaimTemplateName（string, 可选）: 同 resourceClaimName。 */ -}}
  {{- $_resourceClaimTemplateNameRaw := include "base.get" (list . "resourceClaimTemplateName") | trim }}
  {{- $resourceClaimTemplateName := "" }}
  {{- if $_resourceClaimTemplateNameRaw }}
    {{- if not (kindIs "string" (fromYaml (printf "v: %s" $_resourceClaimTemplateNameRaw)).v) }}
      {{- fail (printf "[definitions.podResourceClaim] resourceClaimTemplateName: must be string type, got '%s'" $_resourceClaimTemplateNameRaw) }}
    {{- end }}
    {{- $resourceClaimTemplateName = mustRegexReplaceAll $const.SYS.YAML_QUOTED $_resourceClaimTemplateNameRaw "$1" | trim }}
  {{- end }}

  {{- /* 两个引用字段恰有一个生效: 归一化为空视为未设置，两者同时未设置或同时设置均中断。 */ -}}
  {{- if ne (len (mustCompact (list $resourceClaimName $resourceClaimTemplateName))) 1 }}
    {{- fail "[definitions.podResourceClaim] resourceClaimName/resourceClaimTemplateName: exactly one must be set" }}
  {{- end }}

  {{- /* 输出按 API 字段顺序: name 必填，引用字段由上面的互斥判定保证恰有一个非空。 */ -}}
  {{- include "base.field" (list "name" $name "quote") }}
  {{- if $resourceClaimName }}
    {{- include "base.field" (list "resourceClaimName" $resourceClaimName "quote") }}
  {{- else }}
    {{- include "base.field" (list "resourceClaimTemplateName" $resourceClaimTemplateName "quote") }}
  {{- end }}
{{- end }}
