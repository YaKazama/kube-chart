{{- /*
  variables(slice): any[key(string), value(any), define(string)?, allow(slice)?]
    - index 0: key (字符串，必传)
    - index 1: value (任意类型，必传)
    - index 2: define (处理value的模板名，可选)
    - index 3: allow (允许的值列表，可选)

  return: key: value
*/ -}}
{{- define "base.field" -}}
  {{- if not (kindIs "slice" .) }}
    {{- fail "Must be a slice and requires 2 to 4 parameters. Format: '[key(string), value(any), define(string)?, allow(slice)?]'" }}
  {{- end }}

  {{- $sliceLen := len . }}
  {{- if or (lt $sliceLen 2) (gt $sliceLen 4) }}
    {{- fail (printf "The slice length must be 2-4, but the actual length is %d" $sliceLen) }}
  {{- end }}

  {{- $key := include "base.string" (index . 0) }}
  {{- $rawValue := index . 1 }}
  {{- $define := "base.string" }}
  {{- if eq $sliceLen 3 }}
    {{- $define = index . 2 }}
  {{- end }}
  {{- $val := include $define $rawValue }}
  {{- $isValid := fromYaml $val }}

  {{- if $isValid }}
    {{- if eq $sliceLen 2 }}
      {{- nindent 0 "" -}}{{ $key }}: {{ $val }}
    {{- end }}

    {{- if eq $sliceLen 3 }}
      {{- $isMap := or (contains "map" $define) (contains "object" $define) }}
      {{- $isSlice := or (contains "slice" $define) (contains "array" $define) (contains "list" $define) (contains "tuple" $define) }}
      {{- nindent 0 "" -}}{{ $key }}:
        {{- if $isMap }}
          {{- $val | nindent 2 }}
        {{- else if $isSlice }}
          {{- $val | nindent 0 }}
        {{- else }}
          {{ $val }}
        {{- end }}
    {{- end }}

    {{- if eq $sliceLen 4 }}
      {{- $allow := index . 3 }}
      {{- if mustHas $val $allow }}
        {{- nindent 0 "" -}}{{ $key }}: {{ $val }}
      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}
