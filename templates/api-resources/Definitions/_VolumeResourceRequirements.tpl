{{- /*
  渲染 Kubernetes VolumeResourceRequirements 字段片段。

  行为 (按 K8s API 规范字段顺序):
    - limits (object, 可选): 资源名到 Quantity 的映射，逐值按 K8S Quantity 校验后以原值输出；缺省、null 或空 map 时不输出。
    - requests (object, 可选): 同 limits，并在共同资源键上校验不超过 limits。

  边界:
    - 两个字段均为可选；全部无有效输出时本模板输出空内容，不输出 resources 父键。
    - 只识别 limits 与 requests；base.get 默认开启别名识别，因此 limitsAlias、requestsAlias 隐式生效。
    - 仅比较两侧同时存在的资源键；requests 独有的键不参与比较。
    - 非法 Quantity 由 base.map.verify 中断并保留其自身前缀；非 map 类型由其类型门禁中断。
    - 比较失败由本模板以 [definitions.volumeResourceRequirements] 前缀中断。
    - 除两个字段及其同级别名以外的入参字段静默忽略；不输出 status。

  入参: 上下文 map，可包含以下字段:
    - limits   (object, 可选) 资源上限
    - requests (object, 可选) 资源下限

  返回值: 可嵌入 resources 下的 VolumeResourceRequirements YAML 字段片段；无有效内容时为空。

  示例:
    {{- include "definitions.volumeResourceRequirements" (dict "limits" (dict "storage" "10Gi") "requests" (dict "storage" "5Gi")) }}
*/ -}}
{{- define "definitions.volumeResourceRequirements" -}}
  {{- $const := include "base.env" "" | fromYaml }}
  {{- $limits := dict }}
  {{- $requests := dict }}

  {{- /* limits（object, 可选）: 解码后为空时跳过；非空时经 base.map.verify 按 K8S.QUANTITY 逐值校验并恢复原值。 */ -}}
  {{- $_limitsRaw := include "base.get" (list . "limits") | trim }}
  {{- if $_limitsRaw }}
    {{- $_limitsParsed := fromYaml $_limitsRaw }}
    {{- if eq (include "base.isFromYamlError" $_limitsParsed) "true" }}
      {{- fail "[definitions.volumeResourceRequirements] limits: must be map type" }}
    {{- end }}
    {{- $_limitsMap := fromYaml (include "base.map.verify" (list $_limitsParsed $const.K8S.QUANTITY)) }}
    {{- if eq (include "base.isFromYamlError" $_limitsMap) "true" }}
      {{- fail "[definitions.volumeResourceRequirements] limits: base.map.verify returned invalid YAML" }}
    {{- end }}
    {{- $limits = $_limitsMap }}
  {{- end }}

  {{- /* requests（object, 可选）: 取值、校验与恢复方式同 limits。 */ -}}
  {{- $_requestsRaw := include "base.get" (list . "requests") | trim }}
  {{- if $_requestsRaw }}
    {{- $_requestsParsed := fromYaml $_requestsRaw }}
    {{- if eq (include "base.isFromYamlError" $_requestsParsed) "true" }}
      {{- fail "[definitions.volumeResourceRequirements] requests: must be map type" }}
    {{- end }}
    {{- $_requestsMap := fromYaml (include "base.map.verify" (list $_requestsParsed $const.K8S.QUANTITY)) }}
    {{- if eq (include "base.isFromYamlError" $_requestsMap) "true" }}
      {{- fail "[definitions.volumeResourceRequirements] requests: base.map.verify returned invalid YAML" }}
    {{- end }}
    {{- $requests = $_requestsMap }}
  {{- end }}

  {{- /* 共同资源键比较: 仅当 limits 存在同名键时校验 requests 不超过 limits。 */ -}}
  {{- range $key, $_requestValue := $requests }}
    {{- if hasKey $limits $key }}
      {{- if ne (include "base.quantity.ge" (list (toString (get $limits $key)) (toString $_requestValue))) "true" }}
        {{- fail (printf "[definitions.volumeResourceRequirements] requests.%s: must not exceed limits" $key) }}
      {{- end }}
    {{- end }}
  {{- end }}

  {{- /* 输出按 API 字段顺序: 先 limits 后 requests，使用通过校验的原值。 */ -}}
  {{- if $limits }}
    {{- include "base.field" (list "limits" $limits "base.map") }}
  {{- end }}
  {{- if $requests }}
    {{- include "base.field" (list "requests" $requests "base.map") }}
  {{- end }}
{{- end }}
