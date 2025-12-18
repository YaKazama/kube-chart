{{- /*
  打印失败信息，包括传入的值、类型

  数据格式: dict/map, 包括 iName(string) iValue(string) iLine(int)
*/ -}}
{{- define "base.faild" }}
  {{- fail (printf "%s: Type not support! Values: '%v', Type: %s (%s), Line: %d" .iName .iValue (typeOf .iValue) (kindOf .iValue) (get . "iLine" | default 0)) }}
{{- end }}

{{- /*
  类型校验: invalid 或 nil
*/ -}}
{{- define "base.invalid" -}}
  {{- if kindIs "invalid" . }}
    {{- include "base.faild" (dict "iName" "base.invalid" "iValue" .) }}
  {{- end }}
{{- end }}

{{- /*
  类型校验: empty
*/ -}}
{{- define "base.empty" -}}
  {{- if empty . }}
    {{- include "base.faild" (dict "iName" "base.empty" "iValue" .) }}
  {{- end }}
{{- end }}
