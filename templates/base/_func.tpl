{{- /*
  使用 a.b.c 遍历嵌套的字典取值。参考 dig

  variables:
  - m: Map
  - k: 以分隔符分隔的键字符串 默认使用 base.env 定义下的 regexSplitStr
  - default: 默认值，默认返回空符字串

  return: toYaml 转换后的 YAML 字符串或默认值
*/ -}}
{{- define "base.map.dig" -}}
  {{- if not (kindIs "map" .) }}
    {{- fail "Must be a map(dict)." }}
  {{- end }}

  {{- include "base.invalid" .m }}

  {{- $const := include "base.env" . | fromYaml }}

  {{- $keys := mustRegexSplit $const.regexSplitStr .k -1 }}
  {{- $keysLen := len $keys }}
  {{- $first := mustFirst $keys }}

  {{- if hasKey .m $first }}
    {{- $val := get .m $first }}

    {{- if eq $keysLen 1 }}
      {{- toYamlPretty $val }}
    {{- else }}
      {{- include "base.map.dig" (dict "k" (join "." (mustRest $keys)) "m" $val "default" .default) }}
    {{- end }}
  {{- else }}
    {{- coalesce .default (quote $const.emptyStr) }}
  {{- end }}
{{- end }}


{{- /*
  按 Key 合并多个 Map，支持覆盖策略控制
  Key 键的值会作为新键存在，合并策略由 overwrite 决定：
  - 当 overwrite 为 false 时：从左到右合并，保留左侧键（不覆盖）
  - 当 overwrite 为 true 时：从右到左合并，右侧键覆盖左侧（覆盖）

  variables(slice):
  - index 0: key - 用于提取新键的 Key
  - index 1: overwrite - 布尔值，是否启用覆盖模式
  - index 2+: maps - 待合并的 Map 列表（至少 1 个）

  return: 合并后的新 Map（YAML 格式）
*/ -}}
{{- define "base.map.merge" -}}
  {{- /* 参数校验：必须是切片且至少包含 3 个元素（key, overwrite, 至少1个map） */ -}}
  {{- if or (not (kindIs "slice" .)) (lt (len .) 3) }}
    {{- fail "Must be a slice and requires at least 3 parameters. format: '[key, overwrite(bool), map1, map2, ...]'" }}
  {{- end }}

  {{- /* 提取参数并校验类型 */ -}}
  {{- $key := index . 0 }}
  {{- $overwrite := index . 1 }}
  {{- $maps := mustSlice . 2 }}

  {{- /* 校验 overwrite 必须是布尔值 */ -}}
  {{- if not (kindIs "bool" $overwrite) }}
    {{- fail "The 'overwrite' parameter must be a boolean (true/false)." }}
  {{- end }}

  {{- /* 初始化结果Map */ -}}
  {{- $rslt := dict }}

  {{- /* 根据覆盖策略选择合并方式 */ -}}
  {{- range $maps }}
    {{- if hasKey . $key }}
      {{- $newEntry := dict (get . $key) . }} {{/* 用当前map的key值作为新键 */}}
      {{- if $overwrite }}
        {{- $rslt = mustMergeOverwrite $rslt $newEntry }} {{/* 覆盖模式：右到左合并 */}}
      {{- else }}
        {{- $rslt = mustMerge $rslt $newEntry }} {{/* 非覆盖模式：左到右合并 */}}
      {{- end }}
    {{- end }}
  {{- end }}

  {{- /* 输出合并结果（YAML格式） */ -}}
  {{- toYamlPretty $rslt }}
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

  {{- $len := len . }}

  {{- if eq $len 1 }}
    {{- include "base.int" (index . 0) }}
  {{- else if eq $len 2 }}
    {{- $num := (index . 0) }}
    {{- $min := (index . 1) }}

    {{- include "base.empty" $min }}

    {{- if ge $num $min }}
      {{- include "base.int" $num }}
    {{- else }}
      {{- include "base.faild" . }}
    {{- end }}
  {{- else if eq $len 3 }}
    {{- $num := (index . 0) }}
    {{- $min := (index . 1) }}
    {{- $max := (index . 2) }}

    {{- include "base.empty" $min }}

    {{- if and (ge $num $min) (le $num $max) }}
      {{- include "base.int" $num }}
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
{{- define "base.port" -}}
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

  {{- $const := include "base.env" . | fromYaml }}

  {{- if mustRegexMatch $const.regexIP (toString .) }}
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
    {{- fail (printf "Must be a map(dict). Values: %s, type: %s (%s)" . (typeOf .) (kindOf .)) }}
  {{- end }}

  {{- $const := include "base.env" . | fromYaml }}

  {{- $val := list }}
  {{- $clean := list }}

  {{- $regexSplit := coalesce .r $const.regexSplitStr }}
  {{- $regexCheck := coalesce .c $const.emptyStr }}
  {{- $define := coalesce .define $const.emptyStr }}
  {{- $sep := coalesce .sep $const.emptyStr }}
  {{- $empty := coalesce .empty false }}

  {{- $data := .s }}
  {{- if kindIs "string" .s }}
    {{- $data = list .s }}
  {{- end }}

  {{- range $data }}
    {{- if kindIs "slice" . }}
      {{- $clean = concat $clean (include "base.slice.cleanup" (dict "s" . "r" $regexSplit "c" $regexCheck "define" $define "sep" $sep "empty" $empty) | fromYamlArray) }}
    {{- else if kindIs "map" . }}
      {{- $clean = mustAppend $clean . }}
    {{- else if kindIs "string" . }}
      {{- $val := mustRegexSplit $regexSplit . -1 }}
      {{- $valTmp := list }}
      {{- range $val }}
        {{- if regexMatch $const.regexCheckInt . }}
          {{- $valTmp = append $valTmp (atoi .) }}   {{- /* 纯数字的字符串，使用 int 转换成数字 */ -}}
        {{- else }}
          {{- $valTmp = append $valTmp . }}
        {{- end }}
      {{- end }}
      {{- $clean = concat $clean $valTmp }}
    {{- else if or (kindIs "float64" .) (kindIs "int" .) (kindIs "int64" .) }}
      {{- $clean = mustAppend $clean . }}
    {{- else }}
      {{- include "base.faild" . }}
    {{- end }}
  {{- end }}

  {{- range $clean }}
    {{- if $regexCheck }}
      {{- /* mustRegexMatch 有问题时会向模板引擎返回错误 */ -}}
      {{- $_ := mustRegexMatch $regexCheck (toString .) }}
    {{- end }}

    {{- if $define }}
      {{- $val = mustAppend $val (include $define . | fromYaml) }}
    {{- else }}
      {{- $val = mustAppend $val . }}
    {{- end }}
  {{- end }}

  {{- $val = mustUniq $val }}
  {{- if not $empty }}
    {{- $val = mustCompact $val }}
  {{- end }}

  {{- if $val }}
    {{- if $sep }}
      {{- join $sep $val }}
    {{- else }}
      {{- toYamlPretty $val }}
    {{- end }}
  {{- end }}
{{- end }}


{{- /*
  检查 fileMode 是否合法。支持字符串 0000 - 0777 及数字 0 - 511

  return: 0000 - 0777 (string) / 0 - 511 (int)
*/ -}}
{{- define "base.fileMode" -}}
  {{- include "base.invalid" . }}

  {{- $typesNum := list "float64" "int" "int64" }}
  {{- $typesStr := list "string" }}

  {{- $type := kindOf . }}

  {{- if mustHas $type $typesNum }}
    {{- include "base.int.range" (list . 0 511) }}
  {{- else if mustHas $type $typesStr }}
    {{- $const := include "base.env" . | fromYaml }}

    {{- if mustRegexMatch $const.regexFileMode . }}
      {{- int . }}
    {{- else }}
      {{- include "base.faild" . }}
    {{- end }}
  {{- else }}
    {{- include "base.faild" . }}
  {{- end }}
{{- end }}
