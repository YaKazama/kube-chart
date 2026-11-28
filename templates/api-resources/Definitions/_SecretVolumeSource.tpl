{{- /*
  渲染 Kubernetes SecretVolumeSource 字段片段。

  行为 (按 K8s API 规范字段顺序):
    - defaultMode (integer, 可选): 接受八进制 0000-0777 或十进制 0-511 的数值/字符串，归一化为十进制 int 输出；空值省略。
    - items       (KeyToPath array, 可选): 接受 map 数组、string 数组或两者混合；string 元素按 `<key> <path> [mode]` 解析，`mode` 缺失时不写入；每个元素作为 map 委托 definitions.keyToPath；空结果剔除，完全相同结果保留首个；空数组或全空白省略。
    - optional    (boolean, 可选): 剥离 YAML 引号后省略空值，其余交给 base.bool，显式 false 也输出。
    - secretName  (string, 必填): 解码后 trim 判空，按 RFC1123 Subdomain 校验并以带引号标量输出。

  边界:
    - 只读取 defaultMode、items、optional、secretName，其他字段静默忽略；按 API 顺序输出已生效字段。
    - items 不是数组、元素不是 map/string、string 元素格式非法或子模板输出非法 YAML 时中断。
    - items 的 key、mode、path 校验由 definitions.keyToPath 负责；本模板不重复其内部结构。
    - definitions.keyToPath 对合法输入不产生空输出；空结果剔除仅作为父模板容错。

  入参: map，形如 `{secretName: "app-secret", defaultMode: "0644", items: ["tls.crt tls.crt"]}`。

  返回值: 可嵌入 Volume.secret 位置的 YAML 字段片段。

  示例:
    {{- include "definitions.secretVolumeSource" (dict "secretName" "app-secret") }}
      // secretName: "app-secret"
    {{- include "definitions.secretVolumeSource" (dict "secretName" "app-secret" "defaultMode" "0644" "items" (list "tls.crt tls.crt")) }}
      // defaultMode: 420
      // items:
      //   - key: tls.crt
      //     path: tls.crt
      // secretName: "app-secret"
*/ -}}
{{- define "definitions.secretVolumeSource" -}}
  {{- $const := include "base.env" "" | fromYaml }}
  {{- $_ := "" }}

  {{- /* defaultMode（integer, 可选）: 剥离 YAML 引号后归一化为十进制 int，显式 0 有效。 */ -}}
  {{- $_defaultModeRaw := include "base.get" (list . "defaultMode") | trim }}
  {{- if $_defaultModeRaw }}
    {{- $defaultMode := mustRegexReplaceAll $const.SYS.YAML_QUOTED $_defaultModeRaw "$1" | trim }}
    {{- if $defaultMode }}
      {{- include "base.field" (list "defaultMode" (include "base.fileMode" $defaultMode) "base.int") }}
    {{- end }}
  {{- end }}

  {{- /* items（KeyToPath array, 可选）: map 原样、string 按 `<key> <path> [mode]` 解析；空结果剔除，去重后输出。 */ -}}
  {{- $_items := fromYamlArray (include "base.get" (list . "items")) }}
  {{- if eq (include "base.isFromYamlArrayError" $_items) "true" }}
    {{- fail "[definitions.secretVolumeSource] items: must be array type" }}
  {{- end }}
  {{- $items := list }}
  {{- range $_element := $_items }}
    {{- $itemContext := $_element }}
    {{- if kindIs "string" $_element }}
      {{- $_text := trim $_element }}
      {{- if not $_text }}
        {{- continue }}
      {{- end }}
      {{- $_pattern := $const.K8S.VOLUME.KEY_TO_PATH_ITEM }}
      {{- if not (mustRegexMatch $_pattern $_text) }}
        {{- fail (printf "[definitions.secretVolumeSource] items: '%s' does not match '<key> <path> [mode]'" $_text) }}
      {{- end }}
      {{- $itemContext = dict "key" (mustRegexReplaceAll $_pattern $_text "$1" | trim) "path" (mustRegexReplaceAll $_pattern $_text "$2" | trim) }}
      {{- $_mode := mustRegexReplaceAll $_pattern $_text "$3" | trim }}
      {{- if $_mode }}
        {{- $_ = set $itemContext "mode" $_mode }}
      {{- end }}
    {{- else if not (kindIs "map" $_element) }}
      {{- fail (printf "[definitions.secretVolumeSource] items: each item must be object or string type, got '%s'" (kindOf $_element)) }}
    {{- end }}
    {{- $_parsed := fromYaml (include "definitions.keyToPath" $itemContext) }}
    {{- if eq (include "base.isFromYamlError" $_parsed) "true" }}
      {{- fail "[definitions.secretVolumeSource] items: definitions.keyToPath rendered invalid YAML" }}
    {{- end }}
    {{- if $_parsed }}
      {{- $items = mustAppend $items $_parsed }}
    {{- end }}
  {{- end }}
  {{- $items = mustUniq $items }}
  {{- if $items }}
    {{- include "base.field" (list "items" $items "base.slice") }}
  {{- end }}

  {{- /* optional（boolean, 可选）: 剥离 YAML 引号并 trim 后省略空值，其余交给 base.bool，显式 false 也输出。 */ -}}
  {{- $_optionalRaw := include "base.get" (list . "optional") | trim }}
  {{- if $_optionalRaw }}
    {{- $optional := mustRegexReplaceAll $const.SYS.YAML_QUOTED $_optionalRaw "$1" | trim }}
    {{- if $optional }}
      {{- include "base.field" (list "optional" $optional "base.bool") }}
    {{- end }}
  {{- end }}

  {{- /* secretName（string, 必填）: 解码后 trim 判空，再按 1123sub 校验并以带引号标量输出。 */ -}}
  {{- $secretName := include "base.string.normalize" (include "base.get" (list . "secretName")) | trim }}
  {{- if not $secretName }}
    {{- fail "[definitions.secretVolumeSource] secretName: required field is missing or empty" }}
  {{- end }}
  {{- include "base.field" (list "secretName" (include "base.rfc" (list $secretName "1123sub")) "quote") }}
{{- end }}
