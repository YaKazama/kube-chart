{{- define "definitions.PodFailurePolicyOnPodConditionsPattern" -}}
  {{- $regex := "^(\\S+)(?:\\s+(\\S+))?$" }}

  {{- $match := regexFindAll $regex . -1 }}
  {{- if not $match }}
    {{- fail (printf "PodFailurePolicyOnPodConditionsPattern: error. Values: %s, format: 'type [status]'" .) }}
  {{- end }}

  {{- /* status string */ -}}
  {{- /* 特殊 对字符串 True/False 会被识别为 bool 类型，所以在此特别添加引号 */ -}}
  {{- $status := regexReplaceAll $regex . "${2}" }}
  {{- if $status }}
    {{- include "base.field" (list "status" $status "quote") }}
  {{- end }}

  {{- /* type string */ -}}
  {{- $type := regexReplaceAll $regex . "${1}" }}
  {{- if $type }}
    {{- include "base.field" (list "type" $type) }}
  {{- end }}
{{- end }}
