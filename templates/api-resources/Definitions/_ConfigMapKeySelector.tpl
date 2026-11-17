{{- /*
  渲染 Kubernetes ConfigMapKeySelector 字段片段。

  行为 (按 K8s API 规范字段顺序):
    - key (string, 必填): 按 YAML 标量语义解码后按 K8S.DATA_KEY 校验字符集并以带引号标量输出，缺失或为空白时中断。
    - name (string, 必填): 解码后判空，非空时委托 base.rfc 的 1123sub 模式校验并以带引号标量输出。
    - optional (boolean, 可选): 接受原生布尔值与字符串 true/false，显式 false 也输出。

  边界:
    - 只输出 key、name 与 optional，不包含 configMapKeyRef 父键。
    - 除上述三个字段以外的入参字段静默忽略。
    - key 的字符集由 base.env 的 K8S.DATA_KEY 收口，与 definitions.secretKeySelector 共用，不限首尾字符与最大长度。
    - name 的 RFC1123 Subdomain 与 253 字符上限校验由 base.rfc 收口，失败消息保留其自身前缀。
    - optional 的字符串形态（含 "true"）同样被接受；数字、map、list 与其他字符串视为类型错误。
    - 不校验 name 指向的 ConfigMap 是否存在，也不校验 key 是否存在于该 ConfigMap。

  入参: 上下文 map，可包含以下字段:
    - key      (string, 必填)   ConfigMap 内的键名
    - name     (string, 必填)   ConfigMap 名称
    - optional (boolean, 可选)  ConfigMap 或键缺失时是否允许忽略

  返回值: 可嵌入 configMapKeyRef 位置的 YAML 字段片段。

  示例:
    {{- include "definitions.configMapKeySelector" (dict "name" "app-config" "key" "LOG_LEVEL") }}
    {{- include "definitions.configMapKeySelector" (dict "name" "app-config" "key" "LOG_LEVEL" "optional" true) }}
*/ -}}
{{- define "definitions.configMapKeySelector" -}}
  {{- $const := include "base.env" "" | fromYaml }}

  {{- /* key（string, 必填）: 解码后判空并按 K8S.DATA_KEY 校验字符集，再以带引号标量输出。 */ -}}
  {{- $key := include "base.string.normalize" (include "base.get" (list . "key")) | trim }}
  {{- if not $key }}
    {{- fail "[definitions.configMapKeySelector] key: required field is missing or empty" }}
  {{- end }}
  {{- if not (mustRegexMatch $const.K8S.DATA_KEY $key) }}
    {{- fail (printf "[definitions.configMapKeySelector] key: '%s' is not a valid configmap key" $key) }}
  {{- end }}
  {{- include "base.field" (list "key" $key "quote") }}

  {{- /* name（string, 必填）: 解码后判空，非空时委托 base.rfc 的 1123sub 模式做 RFC1123 Subdomain 与长度校验。 */ -}}
  {{- $name := include "base.string.normalize" (include "base.get" (list . "name")) | trim }}
  {{- if not $name }}
    {{- fail "[definitions.configMapKeySelector] name: required field is missing or empty" }}
  {{- end }}
  {{- include "base.field" (list "name" (include "base.rfc" (list $name "1123sub")) "quote") }}

  {{- /* optional（boolean, 可选）: 剥离 YAML 引号后交给 base.bool 做布尔类型门禁，显式 false 也输出。 */ -}}
  {{- $optional := mustRegexReplaceAll $const.SYS.YAML_QUOTED (include "base.get" (list . "optional") | trim) "$1" | trim }}
  {{- if $optional }}
    {{- include "base.field" (list "optional" $optional "base.bool") }}
  {{- end }}
{{- end }}
