{{- /*
  渲染 Kubernetes SELinuxOptions 字段片段。

  行为 (按 K8s API 规范字段顺序):
    - level (string, 可选): 归一后非空时以带引号标量输出。
    - role  (string, 可选): 同 level。
    - type  (string, 可选): 同 level。
    - user  (string, 可选): 同 level。

  边界:
    - 只输出当前层字段，不输出 seLinuxOptions 父键、apiVersion 或 kind；四个字段均不生效时输出空内容。
    - 字段缺失、为 null、为空字符串或只含空白时跳过该字段；不因全部跳过而失败。
    - 字段不是 string 时由 base.string.normalize 中断，不做类型归一化。
    - 字段值统一以双引号输出，避免 on、yes、true 等文本在父级回收后被解析为布尔。
    - base.get 默认开启别名识别，因此各字段同级 <字段>Alias 隐式生效。
    - 除 level、role、type、user 及其同级别名以外的入参字段静默忽略；不输出 status。

  入参: 上下文 map，可全部省略以下字段:
    - level (string, 可选) SELinux level 标签
    - role  (string, 可选) SELinux role 标签
    - type  (string, 可选) SELinux type 标签
    - user  (string, 可选) SELinux user 标签

  返回值: 可嵌入 seLinuxOptions 下的 SELinuxOptions YAML 字段片段；无有效内容时为空内容。

  示例:
    {{- include "definitions.seLinuxOptions" (dict "level" "s0" "type" "container_t") }}  // level: "s0"
                                                                                          // type: "container_t"
*/ -}}
{{- define "definitions.seLinuxOptions" -}}
  {{- /* level、role、type、user（string, 可选）: 逐键取值并归一等宽处理，跳过空值，统一以带引号标量输出。 */ -}}
  {{- range $_field := list "level" "role" "type" "user" }}
    {{- $value := include "base.string.normalize" (include "base.get" (list $ $_field)) | trim }}
    {{- if $value }}
      {{- include "base.field" (list $_field $value "quote") }}
    {{- end }}
  {{- end }}
{{- end }}
