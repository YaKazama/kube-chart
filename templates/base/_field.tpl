{{- /*
  variables(slice): any[key(string), value(any), define(string), allow(slice)]
  - 2: define 强制为 base.string
  - 3: define 使用传入值
  - 4: define 强制为 base.string

  return: key: value
*/ -}}
{{- define "base.field" -}}
  {{- if not (kindIs "slice" .) }}
    {{- fail "Must be a slice and requires 2 to 4 parameters. Format: '[key(string), value(any), define(string), allow(slice)]'" }}
  {{- end }}

  {{- $__len := len . }}

  {{- if eq $__len 2 }}
    {{- $__key := include "base.string" (index . 0) }}
    {{- $__val := include "base.string" (index . 1) }}

    {{- if (fromYaml $__val) }}
      {{- nindent 0 "" -}}{{ $__key }}: {{ $__val }}
    {{- end }}

  {{- else if eq $__len 3 }}
    {{- $__key := include "base.string" (index . 0) }}
    {{- $__define := index . 2 }}
    {{- $__val := include $__define (index . 1) }}

    {{- if or (contains "map" $__define) (contains "object" $__define) }}
      {{- if (fromYaml $__val) }}
        {{- nindent 0 "" -}}{{ $__key }}:
        {{- $__val | nindent 2 }}
      {{- end }}
    {{- else if or (contains "slice" $__define) (contains "array" $__define) (contains "list" $__define) (contains "tuple" $__define) }}
      {{- if (fromYaml $__val) }}
        {{- nindent 0 "" -}}{{ $__key }}:
        {{- $__val | nindent 0 }}
      {{- end }}
    {{- else }}
      {{- if (fromYaml $__val) }}
        {{- nindent 0 "" -}}{{ $__key }}: {{ $__val }}
      {{- end }}
    {{- end }}

  {{- else if eq $__len 4 }}
    {{- $__key := include "base.string" (index . 0) }}
    {{- $__define := index . 2 }}
    {{- $__val := include $__define (index . 1) }}
    {{- $__allow := index . 3 }}

    {{- if mustHas $__val $__allow }}
      {{- nindent 0 "" -}}{{ $__key }}: {{ $__val }}
    {{- end }}

  {{- else }}
    {{- fail "slice or list index out of range" }}
  {{- end }}
{{- end }}
