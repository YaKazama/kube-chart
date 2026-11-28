{{- /*
  渲染 Kubernetes ClusterTrustBundleProjection 字段片段。

  行为 (按 K8s API 规范字段顺序):
    - labelSelector (LabelSelector, 可选): 为空（缺失、null、空字符串或空 map）时省略且不触发伴随约束；非空时必须为 map，仅允许与 signerName 同时使用，整体委托 definitions.labelSelector。
    - name          (string, 与 signerName 二选一): 解码后 trim 判空，以非空判定生效，并以带引号标量输出。
    - optional      (boolean, 可选): 剥离 YAML 引号后省略空值，其余交给 base.bool，显式 false 也输出。
    - path          (string, 必填): 解码后 trim 判空，归一化为相对路径并拒绝绝对路径；归一化结果为 `..` 或以 `../` 开头时中断；以带引号标量输出。
    - signerName    (string, 与 name 二选一): 解码后 trim 判空，以非空判定生效，并以带引号标量输出。

  边界:
    - name 与 signerName 必须恰好一个非空；两者都为空或都非空时中断。
    - 非空 labelSelector 的内部必填与格式校验由 definitions.labelSelector 负责，其输出为空或非法 YAML 时中断。
    - path 的 trim 与 `.` / `..` 段归一化由 base.path 的 rel 模式完成；前导 `..` 由本模板补足拒绝。
    - 只读取 labelSelector、name、optional、path、signerName，其他字段静默忽略。

  入参: 原生 map，形如 `{name: "trust-bundle", path: "ca.crt"}`。

  返回值: 可嵌入 VolumeProjection.clusterTrustBundle 位置的 YAML 字段片段。

  示例:
    {{- include "definitions.clusterTrustBundleProjection" (dict "name" "trust-bundle" "path" "ca.crt") }}
      // name: "trust-bundle"
      // path: "ca.crt"
    {{- include "definitions.clusterTrustBundleProjection" (dict "signerName" "example.com/signer" "labelSelector" (dict "matchLabels" (dict "app" "web")) "path" "ca.crt") }}
      // labelSelector:
      //   matchLabels:
      //     app: "web"
      // path: "ca.crt"
      // signerName: "example.com/signer"
*/ -}}
{{- define "definitions.clusterTrustBundleProjection" -}}
  {{- $const := include "base.env" "" | fromYaml }}

  {{- /* name 与 signerName（string, 互斥且必须恰好出现一个）: 解码后 trim 判空，按非空判定生效；两者都为空或都非空时中断。 */ -}}
  {{- $name := include "base.string.normalize" (include "base.get" (list . "name")) | trim }}
  {{- $signerName := include "base.string.normalize" (include "base.get" (list . "signerName")) | trim }}
  {{- if eq (empty $name) (empty $signerName) }}
    {{- $_present := list }}
    {{- if $name }}
      {{- $_present = mustAppend $_present "name" }}
    {{- end }}
    {{- if $signerName }}
      {{- $_present = mustAppend $_present "signerName" }}
    {{- end }}
    {{- fail (printf "[definitions.clusterTrustBundleProjection] fields: exactly one of 'name' or 'signerName' is required, got '%v'" (join ", " $_present)) }}
  {{- end }}
  {{- $nameFragment := "" }}
  {{- if $name }}
    {{- $nameFragment = include "base.field" (list "name" $name "quote") }}
  {{- end }}
  {{- $signerNameFragment := "" }}
  {{- if $signerName }}
    {{- $signerNameFragment = include "base.field" (list "signerName" $signerName "quote") }}
  {{- end }}

  {{- /* labelSelector（LabelSelector, 可选）: 为空（缺失、null、空字符串或空 map）时省略且不触发伴随约束；非空时必须为 map，仅允许与 signerName 同时使用，并委托 definitions.labelSelector 渲染。 */ -}}
  {{- $labelSelectorFragment := "" }}
  {{- $_labelSelectorRaw := include "base.get" (list . "labelSelector") | trim }}
  {{- if $_labelSelectorRaw }}
    {{- $labelSelector := fromYaml $_labelSelectorRaw }}
    {{- if eq (include "base.isFromYamlError" $labelSelector) "true" }}
      {{- fail "[definitions.clusterTrustBundleProjection] labelSelector: must be object type" }}
    {{- end }}
    {{- if $labelSelector }}
      {{- if not $signerName }}
        {{- fail "[definitions.clusterTrustBundleProjection] labelSelector: only allowed with signerName" }}
      {{- end }}
      {{- $_rendered := fromYaml (include "definitions.labelSelector" $labelSelector) }}
      {{- if eq (include "base.isFromYamlError" $_rendered) "true" }}
        {{- fail "[definitions.clusterTrustBundleProjection] labelSelector: definitions.labelSelector rendered invalid YAML" }}
      {{- end }}
      {{- if not $_rendered }}
        {{- fail "[definitions.clusterTrustBundleProjection] labelSelector: definitions.labelSelector rendered empty content" }}
      {{- end }}
      {{- $labelSelectorFragment = include "base.field" (list "labelSelector" $_rendered "base.map") }}
    {{- end }}
  {{- end }}

  {{- /* optional（boolean, 可选）: 剥离 YAML 引号并 trim 后省略空值，其余交给 base.bool，显式 false 也输出。 */ -}}
  {{- $optionalFragment := "" }}
  {{- $_optionalRaw := include "base.get" (list . "optional") | trim }}
  {{- if $_optionalRaw }}
    {{- $optional := mustRegexReplaceAll $const.SYS.YAML_QUOTED $_optionalRaw "$1" | trim }}
    {{- if $optional }}
      {{- $optionalFragment = include "base.field" (list "optional" $optional "base.bool") }}
    {{- end }}
  {{- end }}

  {{- /* path（string, 必填）: 解码后 trim 判空，经 rel 模式归一化并拒绝前导 `..`，再以带引号标量输出。 */ -}}
  {{- $path := include "base.string.normalize" (include "base.get" (list . "path")) | trim }}
  {{- if not $path }}
    {{- fail "[definitions.clusterTrustBundleProjection] path: required field is missing or empty" }}
  {{- end }}
  {{- $path = include "base.path" (list $path "rel") }}
  {{- if or (eq $path "..") (hasPrefix "../" $path) }}
    {{- fail (printf "[definitions.clusterTrustBundleProjection] path: '%s' must not be '..' or start with '../'" $path) }}
  {{- end }}
  {{- $pathFragment := include "base.field" (list "path" $path "quote") }}

  {{- /* 按官方字段顺序输出: labelSelector、name、optional、path、signerName。 */ -}}
  {{- $labelSelectorFragment }}{{ $nameFragment }}{{ $optionalFragment }}{{ $pathFragment }}{{ $signerNameFragment }}
{{- end }}
