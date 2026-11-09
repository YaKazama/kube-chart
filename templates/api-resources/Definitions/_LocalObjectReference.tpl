{{- /*
  渲染 Kubernetes LocalObjectReference 字段片段。

  行为 (按 K8s API 规范字段顺序):
    - name (string, 可选): 经 base.get 取值并去除首尾空白与 YAML 标量引号；为空时不输出该字段，非空时按 RFC1035 校验后以带引号标量输出。

  边界:
    - 只输出 name，不包含父级键；父级数组的循环、条目合并与去重由调用方负责。
    - base.get 默认开启别名识别，因此同级 nameAlias 隐式生效，本模板不额外实现别名映射。
    - name 不是 string 时中断；name 不符合 RFC1035 时由 base.rfc 中断，失败消息保留其自身前缀。
    - 除 name 及其同级别名以外的入参字段静默忽略；不输出 status、apiVersion、kind 或其他引用限定字段。

  入参: 上下文 map，由父级传入单个引用项，可包含以下字段:
    - name (string, 可选) 同命名空间内的被引用对象名称

  返回值: 可嵌入 LocalObjectReference 位置的 YAML 字段片段；name 为空时为空内容。

  示例:
    {{- include "definitions.localObjectReference" (dict "name" "regcred") }}  // name: "regcred"
*/ -}}
{{- define "definitions.localObjectReference" -}}
  {{- $const := include "base.env" "" | fromYaml }}

  {{- /* name（string, 可选）: 空值跳过；非空时去引号后按 RFC1035 校验并以带引号标量输出，避免 on、yes 等名称被父级解析为布尔值。 */ -}}
  {{- $_nameRaw := include "base.get" (list . "name") | trim }}
  {{- if $_nameRaw }}
    {{- /* 类型判定必须在去引号之前: 布尔与数值经 base.get 会序列化为同形文本，'"on"' 保留引号时才恢复为 string。 */ -}}
    {{- if not (kindIs "string" (fromYaml (printf "v: %s" $_nameRaw)).v) }}
      {{- fail (printf "[definitions.localObjectReference] name: must be string type, got '%s'" $_nameRaw) }}
    {{- end }}
    {{- $name := mustRegexReplaceAll $const.SYS.YAML_QUOTED $_nameRaw "$1" | trim }}
    {{- if $name }}
      {{- include "base.field" (list "name" (include "base.rfc" (list $name "1035")) "quote") }}
    {{- end }}
  {{- end }}
{{- end }}
