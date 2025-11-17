{{- /*
  打印失败信息，包括传入的值、类型
*/ -}}
{{- define "base.faild" }}
  {{- fail (printf "Type not support! Values: %v, Type: %s(%s)" . (typeOf .) (kindOf .)) }}
{{- end }}

{{- /*
  类型校验: invalid 或 nil
*/ -}}
{{- define "base.invalid" -}}
  {{- if kindIs "invalid" . }}
    {{- include "base.faild" . }}
  {{- end }}
{{- end }}

{{- /*
  类型校验: empty
*/ -}}
{{- define "base.empty" -}}
  {{- if empty . }}
    {{- include "base.faild" . }}
  {{- end }}
{{- end }}
