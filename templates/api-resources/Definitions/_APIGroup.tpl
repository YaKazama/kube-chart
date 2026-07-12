{{- /*
  渲染 Kubernetes APIGroup 资源。参考 https://kubernetes.io/docs/reference/kubernetes-api/definitions/api-group-v1-meta/#APIGroup

  行为 (按 K8s API 规范字段顺序):
    - apiVersion (string, 必填): 固定为 meta/v1, 与 K8s API 规范对齐, 不允许覆盖。
    - kind (string, 必填): 固定为 APIGroup, 与 K8s API 规范对齐, 不允许覆盖。
    - name (string, 必填): 遵循 RFC1035 Label 规范, 由 base.rfc 校验。
    - preferredVersion (string, 可选): 调用 definitions.groupVersionForDiscovery 渲染, 校验前先正则匹配 API_GROUP.GROUP_VERSION_DISCOVERY。
    - serverAddressByClientCIDRs (array, 可选): 元素形如 "clientCIDR serverAddress", 逐项调用 definitions.serverAddressByClientCIDR 渲染, 每项先正则匹配 API_GROUP.SERVER_ADDRESS_BY_CLIENT_CIDR。
    - versions (array, 必填, 非空): 元素形如 "group/version version", 逐项调用 definitions.groupVersionForDiscovery 渲染, 每项先正则匹配 API_GROUP.GROUP_VERSION_DISCOVERY。
    - 禁止渲染 status、metadata 字段 (APIGroup 在 K8s 中无 ObjectMeta 语义)。

  核心字段: 上下文 map, 可包含以下字段:
    - name                          (string, 必填)   APIGroup 名称 (RFC1035 Label, 最多 63 字符)
    - preferredVersion              (string, 可选)   形如 "group/version version", 例如 "meta/v1 v1.23.0"
    - serverAddressByClientCIDRs    (array, 可选)    元素形如 "clientCIDR serverAddress", 例如 ["10.0.0.0/24 10.0.0.1"]
    - versions                      (array, 必填)    元素形如 "group/version version", 例如 ["meta/v1 v1.23.0", "meta/v1beta1 v1.0.0"]

  返回值: APIGroup 资源 YAML 字段 (不含顶级 "---", 由调用方决定)

  示例:
    {{- include "definitions.APIGroup" . }}
*/ -}}
{{- define "definitions.APIGroup" -}}
  {{- /* Step 1: 加载正则常量, Step 5-7 多次复用避免重复 fromYaml 解析 */ -}}
  {{- $const := include "base.env" "" | fromYaml }}

  {{- /* Step 2-3: apiVersion / kind 固定为 meta/v1 / APIGroup, 不允许覆盖 */ -}}
  {{- nindent 0 "" -}}apiVersion: "meta/v1"
  {{- nindent 0 "" -}}kind: "APIGroup"

  {{- /* Step 4: name (string, 必填): RFC1035 Label 规范, 由 base.rfc 校验长度与格式 */ -}}
  {{- $_name := include "base.get" (list . "name") | trim }}
  {{- if or (not $_name) (eq $_name "null") }}
    {{- fail "[definitions.APIGroup] name: required field is missing or empty" }}
  {{- end }}
  {{- $_ := include "base.rfc" (list $_name "1035") }}
  {{- include "base.field" (list "name" $_name "base.string") }}

  {{- /* Step 5: preferredVersion (string, 可选): 正则提取 groupVersion/version 后构造 dict, 转交 definitions.groupVersionForDiscovery 渲染 */ -}}
  {{- $_preferredVersion := include "base.get" (list . "preferredVersion") | trim }}
  {{- if and $_preferredVersion (ne $_preferredVersion "null") }}
    {{- if not (mustRegexMatch $const.API_GROUP.GROUP_VERSION_DISCOVERY $_preferredVersion) }}
      {{- fail (printf "[definitions.APIGroup] preferredVersion: '%s' does not match format 'groupVersion version' (regex: %s)" $_preferredVersion $const.API_GROUP.GROUP_VERSION_DISCOVERY) }}
    {{- end }}

    {{- $_gv := regexReplaceAll $const.API_GROUP.GROUP_VERSION_DISCOVERY $_preferredVersion "${1}" | trim }}
    {{- $_v := regexReplaceAll $const.API_GROUP.GROUP_VERSION_DISCOVERY $_preferredVersion "${2}" | trim }}
    {{- $preferredVersionDict := dict "groupVersion" $_gv "version" $_v }}
    {{- $preferredVersionObj := include "definitions.groupVersionForDiscovery" $preferredVersionDict | fromYaml }}
    {{- if $preferredVersionObj }}
      {{- include "base.field" (list "preferredVersion" $preferredVersionObj "base.map") }}
    {{- end }}
  {{- end }}

  {{- /*
    Step 6: serverAddressByClientCIDRs (array, 可选): 逐项正则提取 clientCIDR/serverAddress 后构造 dict, 渲染为对象列表
    列表字面量特征: "- " 开头 (非空) 或 "[]" (空), 借助 fromYamlArray 解析
    兼容 Helm 4.2.2 fromYamlArray 对非列表输入返回错误切片的 BUG, 委托 base.isFromYamlArrayError 检测
    末尾去重去空: mustUniq | mustCompact
  */ -}}
  {{- $_cidrsRaw := include "base.get" (list . "serverAddressByClientCIDRs") }}
  {{- if and $_cidrsRaw (ne $_cidrsRaw "null") }}
    {{- if not (or (hasPrefix "- " $_cidrsRaw) (eq $_cidrsRaw "[]")) }}
      {{- fail "[definitions.APIGroup] serverAddressByClientCIDRs: not a list type" }}
    {{- end }}

    {{- $cidrs := $_cidrsRaw | fromYamlArray }}
    {{- if eq (include "base.isFromYamlArrayError" $cidrs) "true" }}
      {{- fail "[definitions.APIGroup] serverAddressByClientCIDRs: not a list type" }}
    {{- end }}

    {{- $cidrsList := list }}
    {{- range $c := $cidrs }}
      {{- $cStr := toString $c | trim }}
      {{- if not $cStr }}
        {{- fail "[definitions.APIGroup] serverAddressByClientCIDRs: empty element is not allowed" }}
      {{- end }}

      {{- if not (mustRegexMatch $const.API_GROUP.SERVER_ADDRESS_BY_CLIENT_CIDR $cStr) }}
        {{- fail (printf "[definitions.APIGroup] serverAddressByClientCIDRs: element '%s' does not match format 'clientCIDR serverAddress' (regex: %s)" $cStr $const.API_GROUP.SERVER_ADDRESS_BY_CLIENT_CIDR) }}
      {{- end }}

      {{- $_cidr := regexReplaceAll $const.API_GROUP.SERVER_ADDRESS_BY_CLIENT_CIDR $cStr "${1}" | trim }}
      {{- $_addr := regexReplaceAll $const.API_GROUP.SERVER_ADDRESS_BY_CLIENT_CIDR $cStr "${2}" | trim }}
      {{- $cDict := dict "clientCIDR" $_cidr "serverAddress" $_addr }}
      {{- $cObj := include "definitions.serverAddressByClientCIDR" $cDict | fromYaml }}
      {{- if not $cObj }}
        {{- fail (printf "[definitions.APIGroup] serverAddressByClientCIDRs: element '%s' rendered to empty by definitions.serverAddressByClientCIDR" $cStr) }}
      {{- end }}

      {{- $cidrsList = append $cidrsList $cObj | mustUniq | mustCompact }}
    {{- end }}
    {{- include "base.field" (list "serverAddressByClientCIDRs" $cidrsList "base.slice") }}
  {{- end }}

  {{- /*
    Step 7: versions (array, 必填, 非空): 逐项正则提取 groupVersion/version 后构造 dict, 渲染为对象列表
    列表字面量特征: "- " 开头 (非空) 或 "[]" (空), 借助 fromYamlArray 解析
    兼容 Helm 4.2.2 fromYamlArray 对非列表输入返回错误切片的 BUG, 委托 base.isFromYamlArrayError 检测
    末尾去重去空: mustUniq | mustCompact
  */ -}}
  {{- $_versionsRaw := include "base.get" (list . "versions") }}
  {{- if or (not $_versionsRaw) (eq $_versionsRaw "null") }}
    {{- fail "[definitions.APIGroup] versions: required field is missing or empty" }}
  {{- end }}

  {{- if not (or (hasPrefix "- " $_versionsRaw) (eq $_versionsRaw "[]")) }}
    {{- fail "[definitions.APIGroup] versions: not a list type" }}
  {{- end }}

  {{- $versions := $_versionsRaw | fromYamlArray }}
  {{- if eq (include "base.isFromYamlArrayError" $versions) "true" }}
    {{- fail "[definitions.APIGroup] versions: not a list type" }}
  {{- end }}

  {{- if eq (len $versions) 0 }}
    {{- fail "[definitions.APIGroup] versions: required field is empty (at least 1 element required)" }}
  {{- end }}

  {{- $versionsList := list }}
  {{- range $v := $versions }}
    {{- $vStr := toString $v | trim }}
    {{- if not $vStr }}
      {{- fail "[definitions.APIGroup] versions: empty element is not allowed" }}
    {{- end }}

    {{- if not (mustRegexMatch $const.API_GROUP.GROUP_VERSION_DISCOVERY $vStr) }}
      {{- fail (printf "[definitions.APIGroup] versions: element '%s' does not match format 'groupVersion version' (regex: %s)" $vStr $const.API_GROUP.GROUP_VERSION_DISCOVERY) }}
    {{- end }}

    {{- $_gv := regexReplaceAll $const.API_GROUP.GROUP_VERSION_DISCOVERY $vStr "${1}" | trim }}
    {{- $_v := regexReplaceAll $const.API_GROUP.GROUP_VERSION_DISCOVERY $vStr "${2}" | trim }}
    {{- $vDict := dict "groupVersion" $_gv "version" $_v }}
    {{- $vObj := include "definitions.groupVersionForDiscovery" $vDict | fromYaml }}
    {{- if not $vObj }}
      {{- fail (printf "[definitions.APIGroup] versions: element '%s' rendered to empty by definitions.groupVersionForDiscovery" $vStr) }}
    {{- end }}

    {{- $versionsList = append $versionsList $vObj | mustUniq | mustCompact }}
  {{- end }}
  {{- include "base.field" (list "versions" $versionsList "base.slice") }}
{{- end }}
