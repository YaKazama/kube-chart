{{- /*
  渲染 Kubernetes SecretEnvSource 字段片段。

  行为 (按 K8s API 规范字段顺序):
    - name (string, 必填): 经 base.get 取值并解码，trim 后判空；非空时按 RFC1123 Subdomain 校验并以带引号标量输出。
    - optional (boolean, 可选): 缺失、null、空字符串或仅空白字符串时省略；有效值经 base.bool 校验后输出，显式 false 也输出。

  边界:
    - 只输出 name、optional 字段片段，不包含 secretRef 父键与 envFrom 数组包装。
    - name 的 RFC1123 Subdomain 与 253 字符上限校验由 base.rfc 收口，失败消息保留其自身前缀。
    - optional 的 YAML 外层引号由 base.env 的 SYS.YAML_QUOTED 剥离，其他非法值由 base.bool 中断。
    - 不校验 name 指向的 Secret 是否存在。

  入参: 上下文 map，可包含以下字段:
    - name     (string, 必填)  Secret 名称
    - optional (boolean, 可选) Secret 缺失时是否允许忽略

  返回值: 可嵌入 secretRef 位置的 YAML 字段片段。

  示例:
    {{- include "definitions.secretEnvSource" (dict "name" "app-secret") }}
    {{- include "definitions.secretEnvSource" (dict "name" "app-secret" "optional" false) }}
*/ -}}
{{- define "definitions.secretEnvSource" -}}
  {{- $const := include "base.env" "" | fromYaml }}

  {{- /* name（string, 必填）: 解码后 trim 判空，再按 1123sub 校验并以带引号标量输出。 */ -}}
  {{- $name := include "base.string.normalize" (include "base.get" (list . "name")) | trim }}
  {{- if not $name }}
    {{- fail "[definitions.secretEnvSource] name: required field is missing or empty" }}
  {{- end }}
  {{- include "base.field" (list "name" (include "base.rfc" (list $name "1123sub")) "quote") }}

  {{- /* optional（boolean, 可选）: 剥离 YAML 引号并 trim 后省略空值，其余交给 base.bool，显式 false 也输出。 */ -}}
  {{- $optional := mustRegexReplaceAll $const.SYS.YAML_QUOTED (include "base.get" (list . "optional") | trim) "$1" | trim }}
  {{- if $optional }}
    {{- include "base.field" (list "optional" $optional "base.bool") }}
  {{- end }}
{{- end }}
