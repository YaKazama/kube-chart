{{- /*
  渲染 Kubernetes HostAlias 字段片段。

  行为 (按 K8s API 规范字段顺序):
    - hostnames (string array, 可选): 元素按空白或逗号拆分并逐项校验 DNS 域名格式、去重后输出，单标签纯数字与非字符串元素中断。
    - ip (string, 可选): 按 YAML 标量语义解码后按标准 IPv4 或 IPv6 校验，通过后以带引号标量输出，避免父级 YAML 解析歧义。

  边界:
    - 只输出 hostnames 与 ip，不包含父级键；hostAliases 数组的循环、条目级合并与去重由调用方负责。
    - hostnames 的拆分、域名正则校验、去空与去重委托 base.slice.cleanup，其失败消息使用该能力自身前缀。
    - 两个字段同时为空时输出空内容，仅其中之一为空时中断。

  入参: 上下文 map，可包含以下字段:
    - ip        (string, 可选)    hosts 条目的 IP 地址
    - hostnames (string array, 可选) 该 IP 对应的域名列表

  返回值: 可嵌入 HostAlias 条目的 YAML 字段片段；两者皆空时为空内容，非法入参中断渲染。

  示例:
    {{- include "definitions.hostAlias" (dict "ip" "1.1.1.1" "hostnames" (list "a.example.com")) }}
*/ -}}
{{- define "definitions.hostAlias" -}}
  {{- $const := include "base.env" "" | fromYaml }}

  {{- /* ip（string, 可选）: 按 YAML 标量语义解码并 trim；非字符串值由 base.string.normalize 中断，可匹配范围由后续整体锚定表达式收口。 */ -}}
  {{- $ip := include "base.string.normalize" (include "base.get" (list . "ip")) | trim }}

  {{- /* hostnames（string array, 可选）: fromYamlArray 恢复后排除解析错误，再委托 base.slice.cleanup 拆分、校验与去重。 */ -}}
  {{- $_hostnamesRaw := include "base.get" (list . "hostnames") | fromYamlArray }}
  {{- if and (eq (len $_hostnamesRaw) 1) (hasSuffix "go value of type []interface {}" (lower (first $_hostnamesRaw | toString))) }}
    {{- fail "[definitions.hostAlias] hostnames: must be array type" }}
  {{- end }}
  {{- $hostnames := list }}
  {{- range $_hostname := include "base.slice.cleanup" (list $_hostnamesRaw $const.SPLIT.SPACE_COMMA $const.NET.DOMAIN_NAME "") | fromYamlArray }}
    {{- /* 非字符串元素与被 base.slice.cleanup 数值化的单标签纯数字在此统一中断。 */ -}}
    {{- if not (kindIs "string" $_hostname) }}
      {{- fail (printf "[definitions.hostAlias] hostnames: element must be a DNS domain string, got '%v'" $_hostname) }}
    {{- end }}
    {{- if gt (len $_hostname) 253 }}
      {{- fail (printf "[definitions.hostAlias] hostnames: '%s' exceeds 253 characters" $_hostname) }}
    {{- end }}
    {{- $hostnames = mustAppend $hostnames $_hostname }}
  {{- end }}

  {{- /* 两个字段同时为空时输出空内容，供调用方跳过该条目；仅其中之一为空时中断。 */ -}}
  {{- if or $ip $hostnames }}
    {{- if not $ip }}
      {{- fail "[definitions.hostAlias] ip: required when hostnames is provided" }}
    {{- end }}
    {{- if not $hostnames }}
      {{- fail "[definitions.hostAlias] hostnames: required when ip is provided" }}
    {{- end }}
    {{- if not (or (mustRegexMatch $const.NET.IPV4 $ip) (mustRegexMatch $const.NET.IPV6 $ip)) }}
      {{- fail (printf "[definitions.hostAlias] ip: '%s' is not a standard IPv4 or IPv6 address" $ip) }}
    {{- end }}

    {{- include "base.field" (list "hostnames" $hostnames "base.slice") }}
    {{- include "base.field" (list "ip" $ip "quote") }}
  {{- end }}
{{- end }}
