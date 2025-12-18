{{- define "definitions.PodFailurePolicyOnPodConditionsPattern" -}}
  {{- /* status string */ -}}
  {{- /* 特殊 对字符串 True/False 会被识别为 bool 类型，所以在此特别添加引号 */ -}}
  {{- $status := include "base.getValue" (list . "status") }}
  {{- if $status }}
    {{- include "base.field" (list "status" $status "quote") }}
  {{- end }}

  {{- /* type string */ -}}
  {{- $type := include "base.getValue" (list . "type") }}
  {{- if $type }}
    {{- include "base.field" (list "type" $type) }}
  {{- end }}
{{- end }}
