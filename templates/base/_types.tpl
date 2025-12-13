
{{- /*
  Map 类型检查

  return: toYaml string
*/ -}}
{{- define "base.map" -}}
  {{- include "base.invalid" . }}

  {{- if kindIs "map" . }} {{- /* Map 为空也合法 */ -}}
    {{- /* {{- toYamlPretty . | replace "'" "\"" }} 可将单引号强制换为双引号，对 CronJob 中的 schedule 有奇效 */ -}}
    {{- toYamlPretty . }}
  {{- else }}
    {{- include "base.faild" (dict "iName" "base.map" "iValue" . "iLine" 14) }}
  {{- end }}
{{- end }}


{{- /*
  检查 bool 类型

  return: true/false
*/ -}}
{{- define "base.bool" -}}
  {{- include "base.invalid" . }}

  {{- if kindIs "bool" . }}
    {{- . }}
  {{- else if kindIs "string" . }}
    {{- if or (eq . "true") (eq . "false") }}
      {{- . }}
    {{- end }}
  {{- else }}
    {{- include "base.faild" (dict "iName" "base.bool" "iValue" . "iLine" 34) }}
  {{- end }}
{{- end }}


{{- /*
  float64 / int / int64 类型检查

  return: 值或打印报错信息
*/ -}}
{{- define "base.int" -}}
  {{- include "base.invalid" . }}

  {{- $typesNum := list "float64" "int" "int64" }}
  {{- $typesStr := list "string" }}

  {{- $type := kindOf . }}

  {{- if mustHas $type $typesNum }}
    {{- /* float64 精度只有 15 位，从 16 位开始四舍五入 */ -}}
    {{- /* 此处直接强制转为 int 类型，但会丢失小数位后的所有内容，这似乎适用于大部分场景 */ -}}
    {{- /* 若确实需要原样返回，在定义时添加双引号，使用字符串即可 */ -}}
    {{- int . }}
  {{- else if mustHas $type $typesStr }}
    {{- $const := include "base.env" "" | fromYaml }}

    {{- if mustRegexMatch $const.regexCheckInt . }}
      {{- $val := atoi . }}
      {{- if eq $val 9223372036854775807 }}
        {{- . }}
      {{- else }}
        {{- $val }}
      {{- end }}
    {{- else }}
      {{- include "base.faild" (dict "iName" "base.int" "iValue" . "iLine" 68) }}
    {{- end }}
  {{- else }}
    {{- include "base.faild" (dict "iName" "base.int" "iValue" . "iLine" 71) }}
  {{- end }}
{{- end }}


{{- /*
  string 类型检查。传入的是一个非空字符串

  descr:
    - 去掉开头 "0" 值和前后空格的字符串
    - 否 => 打印报错信息

  return: string
    - 全为 0 => 返回 "0"
    - 以 0 开头且全为数字 => 开头只保留一个 0
    - 八进制和十六进制字符串 以 0x, 0o 开头 => 直接原样输出
    - 默认 => 原值（不带双引号）
*/ -}}
{{- define "base.string" -}}
  {{- include "base.invalid" . }}

  {{- $const := include "base.env" "" | fromYaml }}

  {{- if kindIs "string" . }}
    {{- /* 字符串全为 0 。包括 UID="0000"（不能有 +/- 符号） */ -}}
    {{- /* 字符串以 0 开头且全为数字。包括 UMASK="022"（不能有 +/- 符号） */ -}}
    {{- if mustRegexMatch $const.regexReplaceZero . }}
      {{- mustRegexReplaceAll $const.regexReplaceZero . "${1}0${2}" | trim }}
    {{- /* 八进制和十六进制字符串 以 0x, 0o 开头 */ -}}
    {{- else if mustRegexMatch $const.regexOctalHex . }}
      {{- . | trim }}
    {{- /* 默认 原值（不带双引号） */ -}}
    {{- else }}
      {{- . | trim }}
    {{- end }}
  {{- else }}
    {{- include "base.faild" (dict "iName" "base.string" "iValue" . "iLine" 107) }}
  {{- end }}
{{- end }}


{{- /*
  slice 类型检查。传入需要检查的对象即可

  return: slice
*/ -}}
{{- define "base.slice" -}}
  {{- include "base.invalid" . }}

  {{- if kindIs "slice" . }}
    {{- toYamlPretty . }}
  {{- else }}
    {{- include "base.faild" (dict "iName" "base.slice" "iValue" . "iLine" 123) }}
  {{- end }}
{{- end }}


{{- /*
  float64 转 int
*/ -}}
{{- define "base.ftoi" -}}
  {{- include "base.invalid" . }}

  {{- if kindIs "float64" . }}
    {{- int . }}
  {{- else }}
    {{- include "base.faild" (dict "iName" "base.ftoi" "iValue" . "iLine" 137) }}
  {{- end }}
{{- end }}


{{- /*
  bool 转 string
*/ -}}
{{- define "base.btoa" -}}
  {{- include "base.invalid" . }}

  {{- if kindIs "bool" . }}
    {{- toString . }}
  {{- else }}
    {{- include "base.faild" (dict "iName" "base.btoa" "iValue" . "iLine" 151) }}
  {{- end }}
{{- end }}
