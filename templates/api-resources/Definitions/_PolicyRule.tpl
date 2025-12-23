{{- define "definitions.PolicyRule" -}}
  {{- $const := include "base.env" "" | fromYaml }}

  {{- /* apiGroups string array */ -}}
  {{- $apiGroups := include "base.getValue" (list . "apiGroups") }}
  {{- if $apiGroups }}
    {{- $isNotSlice := include "base.isFromYamlArrayError" ($apiGroups | fromYamlArray) }}
    {{- $isNotMap := include "base.isFromYamlError" ($apiGroups | fromYaml) }}
    {{- $val := list }}
    {{- /* 不是 list 或 map 则当作字符串处理  map 不处理 */ -}}
    {{- if and (eq $isNotSlice "true") (eq $isNotMap "true") }}
      {{- $val = include "base.slice.cleanup" (dict "s" $apiGroups "empty" true) | fromYamlArray }}
    {{- /* 处理 slice */ -}}
    {{- else if eq $isNotSlice "false" }}
      {{- $val = $apiGroups | fromYamlArray }}
    {{- end }}

    {{- include "base.field" (list "apiGroups" $val "base.slice") }}
  {{- end }}

  {{- /* nonResourceURLs string array */ -}}
  {{- $nonResourceURLs := include "base.getValue" (list . "nonResourceURLs") }}
  {{- if $nonResourceURLs }}
    {{- $isNotSlice := include "base.isFromYamlArrayError" ($nonResourceURLs | fromYamlArray) }}
    {{- $isNotMap := include "base.isFromYamlError" ($nonResourceURLs | fromYaml) }}
    {{- $val := list }}
    {{- /* 不是 list 或 map 则当作字符串处理  map 不处理 */ -}}
    {{- if and (eq $isNotSlice "true") (eq $isNotMap "true") }}
      {{- $val = include "base.slice.cleanup" (dict "s" $nonResourceURLs "empty" true) | fromYamlArray }}
    {{- /* 处理 slice */ -}}
    {{- else if eq $isNotSlice "false" }}
      {{- $val = $nonResourceURLs | fromYamlArray }}
    {{- end }}

    {{- include "base.field" (list "nonResourceURLs" $val "base.slice") }}
  {{- end }}

  {{- /* resourceNames string array */ -}}
  {{- $resourceNames := include "base.getValue" (list . "resourceNames") }}
  {{- if $resourceNames }}
    {{- $isNotSlice := include "base.isFromYamlArrayError" ($resourceNames | fromYamlArray) }}
    {{- $isNotMap := include "base.isFromYamlError" ($resourceNames | fromYaml) }}
    {{- $val := list }}
    {{- /* 不是 list 或 map 则当作字符串处理  map 不处理 */ -}}
    {{- if and (eq $isNotSlice "true") (eq $isNotMap "true") }}
      {{- $val = include "base.slice.cleanup" (dict "s" $resourceNames "empty" true) | fromYamlArray }}
    {{- /* 处理 slice */ -}}
    {{- else if eq $isNotSlice "false" }}
      {{- $val = $resourceNames | fromYamlArray }}
    {{- end }}

    {{- include "base.field" (list "resourceNames" $val "base.slice") }}
  {{- end }}

  {{- /* resources string array */ -}}
  {{- $resources := include "base.getValue" (list . "resources") }}
  {{- if $resources }}
    {{- $isNotSlice := include "base.isFromYamlArrayError" ($resources | fromYamlArray) }}
    {{- $isNotMap := include "base.isFromYamlError" ($resources | fromYaml) }}
    {{- $val := list }}
    {{- /* 不是 list 或 map 则当作字符串处理  map 不处理 */ -}}
    {{- if and (eq $isNotSlice "true") (eq $isNotMap "true") }}
      {{- $val = include "base.slice.cleanup" (dict "s" $resources "empty" true) | fromYamlArray }}
    {{- /* 处理 slice */ -}}
    {{- else if eq $isNotSlice "false" }}
      {{- $val = $resources | fromYamlArray }}
    {{- end }}

    {{- include "base.field" (list "resources" $val "base.slice") }}
  {{- end }}

  {{- /* verbs string array */ -}}
  {{- $verbs := include "base.getValue" (list . "verbs") }}
  {{- if $verbs }}
    {{- $isNotSlice := include "base.isFromYamlArrayError" ($verbs | fromYamlArray) }}
    {{- $isNotMap := include "base.isFromYamlError" ($verbs | fromYaml) }}
    {{- $val := list }}
    {{- /* 不是 list 或 map 则当作字符串处理  map 不处理 */ -}}
    {{- if and (eq $isNotSlice "true") (eq $isNotMap "true") }}
      {{- $val = include "base.slice.cleanup" (dict "s" $verbs "empty" true) | fromYamlArray }}
    {{- /* 处理 slice */ -}}
    {{- else if eq $isNotSlice "false" }}
      {{- $val = $verbs | fromYamlArray }}
    {{- end }}

    {{- include "base.field" (list "verbs" $val "base.slice") }}
  {{- end }}
{{- end }}
