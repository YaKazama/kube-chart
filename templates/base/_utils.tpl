{{- /*
  统一错误上报，通过 fail 中止渲染并输出标准化消息。

  行为:
    - 验证模板名与可选的失败值、行号；无效参数立即中止。
    - 行号大于 0 时在消息中附加 line N 后缀。

  入参: list [模板名, 失败值, 行号]；模板名必填，后两项可选。

  边界:
    - 仅负责构造并触发 fail，不返回可供调用方继续处理的值。

  返回值: 无；通过 fail 中止渲染。

  示例:
    {{- include "base.failed" (list "base.ftoi" .) }}
    {{- include "base.failed" (list "base.int" . 1) }}
*/ -}}
{{- define "base.failed" -}}
  {{- /* 快速失败: 校验入参必须为 slice */ -}}
  {{- if not (kindIs "slice" .) }}
    {{- fail (printf "[base.failed] parameter: must be slice type, got '%s'" (kindOf .)) }}
  {{- end }}

  {{- $len := len . }}
  {{- /* 快速失败: 至少需要 1 个元素 (name) */ -}}
  {{- if lt $len 1 }}
    {{- fail "[base.failed] parameter: at least 1 element required (name), got 0" }}
  {{- end }}

  {{- /* 快速失败: 校验 name 必须为非空字符串 */ -}}
  {{- $name := index . 0 }}
  {{- if not (kindIs "string" $name) }}
    {{- fail (printf "[base.failed] parameter (name): must be string type, got '%s'" (kindOf $name)) }}
  {{- end }}
  {{- if eq $name "" }}
    {{- fail "[base.failed] parameter (name): must not be empty" }}
  {{- end }}

  {{- /* 可选参数 value, 未提供时默认为空字符串 */ -}}
  {{- $value := "" }}
  {{- if ge $len 2 }}
    {{- $value = index . 1 }}
  {{- end }}

  {{- /* 可选参数 line, 校验类型为 int 且非负 */ -}}
  {{- $line := 0 }}
  {{- if ge $len 3 }}
    {{- $line = index . 2 }}
    {{- if not (kindIs "int" $line) }}
      {{- fail (printf "[base.failed] parameter (line): must be int type, got '%s'" (kindOf $line)) }}
    {{- end }}
    {{- if lt $line 0 }}
      {{- fail (printf "[base.failed] parameter (line): must be non-negative, got '%d'" $line) }}
    {{- end }}
  {{- end }}

  {{- /* 根据 line 是否大于 0 决定错误消息格式 */ -}}
  {{- if gt $line 0 }}
    {{- fail (printf "[%s] line %d: invalid value '%v' (kind: %s)" $name $line $value (kindOf $value)) }}
  {{- else }}
    {{- fail (printf "[%s] invalid value '%v' (kind: %s)" $name $value (kindOf $value)) }}
  {{- end }}
{{- end }}
