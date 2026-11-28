{{- /*
  渲染 Kubernetes ConfigMapProjection 字段片段。

  行为 (按 K8s API 规范字段顺序):
    - items    (KeyToPath array, 可选): 原生 map 逐项委托 definitions.keyToPath，空结果剔除，完全相同结果保留首个；空数组或全空结果省略。
    - name     (string, 必填): 解码后 trim 判空，按 RFC1123 Subdomain 校验并以带引号标量输出。
    - optional (boolean, 可选): 剥离 YAML 引号后省略空值，其余交给 base.bool，显式 false 也输出。

  边界:
    - 只读取 items、name、optional，其他字段静默忽略；按 API 顺序输出已生效字段。
    - items 不是数组、条目不是 map 或子模板输出非法 YAML 时中断。
    - items 的 key、mode、path 校验由 definitions.keyToPath 负责；本模板不重复其内部结构。
    - definitions.keyToPath 对合法输入不产生空输出；空结果剔除仅作为父模板容错。

  入参: 原生 map，形如 `{name: "app-config", items: [{key: "LOG_LEVEL", path: "app/config.conf"}]}`。

  返回值: 可嵌入 VolumeProjection.configMap 位置的 YAML 字段片段。

  示例:
    {{- include "definitions.configMapProjection" (dict "name" "app-config") }}
      // name: "app-config"
    {{- include "definitions.configMapProjection" (dict "name" "app-config" "items" (list (dict "key" "LOG_LEVEL" "path" "app/config.conf")) "optional" false) }}
      // items:
      //   - key: "LOG_LEVEL"
      //     path: "app/config.conf"
      // name: "app-config"
      // optional: false
*/ -}}
{{- define "definitions.configMapProjection" -}}
  {{- $const := include "base.env" "" | fromYaml }}

  {{- /* items（KeyToPath array, 可选）: 原生 map 逐项委托 definitions.keyToPath，空结果剔除并去重；空数组或全空结果省略。 */ -}}
  {{- $_items := fromYamlArray (include "base.get" (list . "items")) }}
  {{- if eq (include "base.isFromYamlArrayError" $_items) "true" }}
    {{- fail "[definitions.configMapProjection] items: must be array type" }}
  {{- end }}
  {{- $items := list }}
  {{- range $_item := $_items }}
    {{- if not (kindIs "map" $_item) }}
      {{- fail (printf "[definitions.configMapProjection] items: each item must be object type, got '%s'" (kindOf $_item)) }}
    {{- end }}
    {{- $_rendered := fromYaml (include "definitions.keyToPath" $_item) }}
    {{- if eq (include "base.isFromYamlError" $_rendered) "true" }}
      {{- fail "[definitions.configMapProjection] items: definitions.keyToPath rendered invalid YAML" }}
    {{- end }}
    {{- if $_rendered }}
      {{- $items = mustAppend $items $_rendered }}
    {{- end }}
  {{- end }}
  {{- $items = mustUniq $items }}
  {{- if $items }}
    {{- include "base.field" (list "items" $items "base.slice") }}
  {{- end }}

  {{- /* name（string, 必填）: 解码后 trim 判空，再按 1123sub 校验并以带引号标量输出。 */ -}}
  {{- $name := include "base.string.normalize" (include "base.get" (list . "name")) | trim }}
  {{- if not $name }}
    {{- fail "[definitions.configMapProjection] name: required field is missing or empty" }}
  {{- end }}
  {{- include "base.field" (list "name" (include "base.rfc" (list $name "1123sub")) "quote") }}

  {{- /* optional（boolean, 可选）: 剥离 YAML 引号并 trim 后省略空值，其余交给 base.bool，显式 false 也输出。 */ -}}
  {{- $_optionalRaw := include "base.get" (list . "optional") | trim }}
  {{- if $_optionalRaw }}
    {{- $optional := mustRegexReplaceAll $const.SYS.YAML_QUOTED $_optionalRaw "$1" | trim }}
    {{- if $optional }}
      {{- include "base.field" (list "optional" $optional "base.bool") }}
    {{- end }}
  {{- end }}
{{- end }}
