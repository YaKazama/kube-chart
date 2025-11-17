{{- /*
  使用 a.b.c 遍历嵌套的字典取值。参考 dig

  variables:
  - m: Map
  - k: 以分隔符分隔的键字符串
    - 分隔符: "."、":"
  - default: 默认值，默认返回空符字串

  return: toYaml 转换后的 YAML 字符串或默认值
*/ -}}
{{- define "base.map.dig" -}}
  {{- if not (kindIs "map" .) }}
    {{- fail "Must be a map(dict)." }}
  {{- end }}

  {{- include "base.invalid" .m }}

  {{- $__const := include "base.env" . | fromYaml }}

  {{- $__keys := mustRegexSplit $__const.regexSplitStr .k -1 }}
  {{- $__keysLen := len $__keys }}
  {{- $__first := mustFirst $__keys }}

  {{- if hasKey .m $__first }}
    {{- $__val := get .m $__first }}

    {{- if eq $__keysLen 1 }}
      {{- toYaml $__val }}
    {{- else }}
      {{- include "base.map.dig" (dict "k" (join "." (mustRest $__keys)) "m" $__val "default" .default) }}
    {{- end }}
  {{- else }}
    {{- coalesce .default (quote $__const.emptyStr) }}
  {{- end }}
{{- end }}


{{- /*
  按 Key 从左到右合并多个 Map
  Key 对应的值会作为新键存在

  variables:
  - k: 用于提取新键的 Key
  - s: 待合并的 Map 列表

  return: 合并后的新 Map
*/ -}}
{{- define "base.map.merge" -}}
  {{- if not (kindIs "map" .) }}
    {{- fail "Must be a map(dict)." }}
  {{- end }}

  {{- $__key := .k }}
  {{- $__maps := .s }}
  {{- $__rslt := dict }}

  {{- range $__maps }}
    {{- if hasKey . $__key }}
      {{- $__rslt = mustMerge $__rslt (dict (get . $__key) .) }}
    {{- end }}
  {{- end }}

  {{- toYaml $__rslt }}
{{- end }}


{{- /*
  按 Key 从右到左合并多个 Map
  Key 对应的值会作为新键存在

  variables:
  - k: 用于提取新键的 Key
  - s: 待合并的 Map 列表

  return: 合并后的新 Map
*/ -}}
{{- define "base.map.mergeOverwrite" -}}
  {{- if not (kindIs "map" .) }}
    {{- fail "Must be a map(dict)." }}
  {{- end }}

  {{- $__key := .k }}
  {{- $__maps := .s }}
  {{- $__rslt := dict }}

  {{- range $__maps }}
    {{- if hasKey . $__key }}
      {{- $__rslt = mustMergeOverwrite $__rslt (dict (get . $__key) .) }}
    {{- end }}
  {{- end }}

  {{- toYaml $__rslt }}
{{- end }}


{{- /*
  检查 float64 / int / int64 类型是否在指定范围内

  variables:
  - int[]{number, min, max}
    - slice 为 1 => 作为 number 直接返回
    - slice 为 2 => 分别为 number, min
    - slice 大于 2 => 只取前 3 个值，分别为 number, min, max

  return: number 或打印报错信息
*/ -}}
{{- define "base.int.range" -}}
  {{- if not (kindIs "slice" .) }}
    {{- fail "Must be a slice or list." }}
  {{- end }}

  {{- $__len := len . }}

  {{- if eq $__len 1 }}
    {{- include "base.int" (index . 0) }}
  {{- else if eq $__len 2 }}
    {{- $__num := (index . 0) }}
    {{- $__min := (index . 1) }}

    {{- include "base.empty" $__min }}

    {{- if ge $__num $__min }}
      {{- include "base.int" $__num }}
    {{- else }}
      {{- include "base.faild" . }}
    {{- end }}
  {{- else if eq $__len 3 }}
    {{- $__num := (index . 0) }}
    {{- $__min := (index . 1) }}
    {{- $__max := (index . 2) }}

    {{- include "base.empty" $__min }}

    {{- if and (ge $__num $__min) (le $__num $__max) }}
      {{- include "base.int" $__num }}
    {{- else }}
      {{- include "base.faild" . }}
    {{- end }}
  {{- else }}
    {{- include "base.faild" . }}
  {{- end }}
{{- end }}


{{- /*
  检查 port 是否在 1 - 65535 范围内。匹配: min <= port <= max

  return: int
*/ -}}
{{- define "base.port.range" -}}
  {{- if and (ge (int .) 1) (le (int .) 65535) }}
    {{- int . }}
  {{- else }}
    {{- include "base.faild" . }}
  {{- end }}
{{- end }}

{{- /*
  检查 IP 地址是否合法

  return: string
*/ -}}
{{- define "base.ip" -}}
  {{- include "base.invalid" . }}

  {{- $__const := include "base.env" . | fromYaml }}

  {{- if mustRegexMatch $__const.regexIP (toString .) }}
    {{- . }}
  {{- else }}
    {{- include "base.faild" . }}
  {{- end }}
{{- end }}


{{- /*
  string 允许显示空字符串 ""
  注: "空" 定义取决于以下类型：
    整型: 0
    字符串: ""
    列表: []
    字典: {}
    布尔: false
    以及所有的nil (或 null)

  return: 原值或空字符串
*/ -}}
{{- define "base.string.empty" -}}
  {{- if empty . }}
    {{- quote "" }}
  {{- else }}
    {{- include "base.string" . }}
  {{- end }}
{{- end }}


{{- /*
  格式化 slice 类型数据为 string array

  variables:
  - s(slice): 数据源
    - string: a, b,c d
    - slice / list:
      - [a, b, c]
      - [{name: a}, {name: b}]
    - int / int64 / float64:
      - 1, 2, 3
      - [4, 5, 6]
  - r(string): 字符串分隔符：","、"."、":"、"|"、"/"、"*"、"^"、"@"、"#"、"\s"
  - c(string): 用于字符串检查的正则表达式，验证清洗后的字符串是否合法，不合法的值会报错
  - define(string): 定义的模板名称，用于处理清洗后的数据
  - sep(string): 分隔符，用于将列表转为字符串作为连字符
  - empty(bool): 是否允许出现空字符串 ""

  return: string array 格式或 join 后的字符串
*/ -}}
{{- define "base.slice.cleanup" -}}
  {{- if not (kindIs "map" .) }}
    {{- fail "Must be a map(dict)." }}
  {{- end }}

  {{- $__const := include "base.env" . | fromYaml }}

  {{- $__val := list }}
  {{- $__clean := list }}

  {{- $__regexSplit := coalesce .r $__const.regexSplitStr }}
  {{- $__regexCheck := coalesce .c $__const.emptyStr }}
  {{- $__define := coalesce .define $__const.emptyStr }}
  {{- $__sep := coalesce .sep $__const.emptyStr }}
  {{- $__empty := coalesce .empty false }}

  {{- $__data := .s }}
  {{- if kindIs "string" .s }}
    {{- $__data = list .s }}
  {{- end }}

  {{- range $__data }}
    {{- if kindIs "slice" . }}
      {{- $__clean = concat $__clean (include "base.slice.cleanup" (dict "s" . "r" $__regexSplit "c" $__regexCheck "define" $__define "sep" $__sep "empty" $__empty) | fromYaml) }}
    {{- else if kindIs "map" . }}
      {{- $__clean = mustAppend $__clean . }}
    {{- else if kindIs "string" . }}
      {{- $__clean = concat $__clean (mustRegexSplit $__regexSplit . -1) }}
    {{- else if or (kindIs "float64" .) (kindIs "int" .) (kindIs "int64" .) }}
      {{- $__clean = mustAppend $__clean . }}
    {{- else }}
      {{- include "base.faild" . }}
    {{- end }}
  {{- end }}

  {{- range $__clean }}
    {{- if $__regexCheck }}
      {{- /* mustRegexMatch 有问题时会向模板引擎返回错误 */ -}}
      {{- $_ := mustRegexMatch $__regexCheck (toString .) }}
    {{- end }}

    {{- if $__define }}
      {{- $__val = mustAppend $__val (include $__define . | fromYaml) }}
    {{- else }}
      {{- $__val = mustAppend $__val . }}
    {{- end }}
  {{- end }}

  {{- $__val = mustUniq $__val }}
  {{- if not $__empty }}
    {{- $__val = mustCompact $__val }}
  {{- end }}

  {{- if $__val }}
    {{- if $__sep }}
      {{- join $__sep $__val }}
    {{- else }}
      {{- toYaml $__val | indent 0 }}
    {{- end }}
  {{- end }}
{{- end }}


{{- /*
  检查 fileMode 是否合法。支持字符串 0000 - 0777 及数字 0 - 511

  return: 0000 - 0777 (string) / 0 - 511 (int)
*/ -}}
{{- define "base.fileMode" -}}
  {{- include "base.invalid" . }}

  {{- $__typesNum := list "float64" "int" "int64" }}
  {{- $__typesStr := list "string" }}

  {{- $__type := kindOf . }}

  {{- if mustHas $__type $__typesNum }}
    {{- include "base.int.range" (list . 0 511) }}
  {{- else if mustHas $__type $__typesStr }}
    {{- $__const := include "base.env" . | fromYaml }}

    {{- if mustRegexMatch $__const.regexFileMode . }}
      {{- int . }}
    {{- else }}
      {{- include "base.faild" . }}
    {{- end }}
  {{- else }}
    {{- include "base.faild" . }}
  {{- end }}
{{- end }}
