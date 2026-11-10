{{- /*
  渲染 Kubernetes PodOS 字段片段。

  行为 (按 K8s API 规范字段顺序):
    - name (string, 可选): 经 base.get 取值并按 YAML 标量语义解码，转小写；为空时不输出该字段，非空时按 linux、windows 枚举校验后输出。

  边界:
    - 只输出 name，不包含父级键；字符串简写归一化由调用方负责。
    - base.get 默认开启别名识别，因此同级 nameAlias 隐式生效，本模板不额外实现别名映射。
    - name 不是 string 时由 base.string.normalize 中断，失败消息使用其自身前缀。
    - name 归一化后不是 linux、windows 时由 base.field 中断，失败消息保留其自身前缀。
    - 除 name 及其同级别名以外的入参字段静默忽略；不输出 status、apiVersion、kind。

  入参: 上下文 map，由父级传入单个操作系统描述，可包含以下字段:
    - name (string, 可选) 操作系统名，大小写不敏感，取值 linux、windows

  返回值: 可嵌入 os 下的 PodOS YAML 字段片段；name 为空时为空内容。

  示例:
    {{- include "definitions.podOS" (dict "name" "Linux") }}  // name: linux
*/ -}}
{{- define "definitions.podOS" -}}
  {{- /* name（string, 可选）: 空值跳过；非空时按 YAML 标量语义解码并转小写，再由 base.field 完成枚举校验与输出。 */ -}}
  {{- $name := lower (include "base.string.normalize" (include "base.get" (list . "name")) | trim) }}
  {{- if $name }}
    {{- include "base.field" (list "name" $name "base.string" (list "linux" "windows")) }}
  {{- end }}
{{- end }}
