{{- /*
  variables(slice): any[key(string), value(any), define(string)?, allow(slice)?]
    - index 0: key (字符串，必传)
    - index 1: value (任意类型，必传)
    - index 2: define (处理value的模板名，可选) / "quote" (是否添加双引号，可选) (quote 是一个特殊的关键字, 同时 define 也会强制设置为 base.string)
    - index 3: allow (允许的值列表，可选) (define 会强制设置为 base.string)

  return: key: value
*/ -}}
{{- define "base.field" -}}
  {{- if not (kindIs "slice" .) }}
    {{- fail "Must be a slice and requires 2 to 4 parameters. Format: '[key(string), value(any), define(string)?, allow(slice)?]'" }}
  {{- end }}

  {{- $sliceLen := len . }}

  {{- $key := include "base.string" (index . 0) }}
  {{- $rawValue := index . 1 }}
  {{- $define := "base.string" }}
  {{- if eq $sliceLen 3 }}
    {{- $define = index . 2 }}
  {{- end }}
  {{- $isQuote := false }}
  {{- if eq $define "quote" }}
    {{- $isQuote = true }}
  {{- end }}
  {{- if or (eq $sliceLen 4) $isQuote }}  {{- /* 强制 define = base.string */ -}}
    {{- $define = "base.string" }}
  {{- end }}
  {{- $val := include $define $rawValue }}
  {{- if $isQuote }}
    {{- $val = $val | quote }}
  {{- end }}

  {{- if eq $sliceLen 2 }}
    {{- nindent 0 "" -}}{{ $key }}: {{ $val }}
  {{- end }}

  {{- if eq $sliceLen 3 }}
    {{- $isMap := or (contains "map" $define) (contains "object" $define) }}
    {{- $isSlice := or (contains "slice" $define) (contains "array" $define) (contains "list" $define) (contains "tuple" $define) }}
      {{- if or $isMap $isSlice }}
        {{- nindent 0 "" -}}{{ $key }}:
        {{- $val | nindent 2 }}
      {{- else }}
        {{- nindent 0 "" -}}{{ $key }}: {{ $val }}
      {{- end }}
  {{- end }}

  {{- if eq $sliceLen 4 }}
    {{- /* 不在列表中的，会直接丢弃 */ -}}
    {{- $allow := index . 3 }}
    {{- if mustHas $val $allow }}
      {{- nindent 0 "" -}}{{ $key }}: {{ $val }}
    {{- end }}
  {{- end }}
{{- end }}
