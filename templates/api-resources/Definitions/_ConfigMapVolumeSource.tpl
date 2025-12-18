{{- define "definitions.ConfigMapVolumeSource" -}}
  {{- /* defaultMode int */ -}}
  {{- $defaultMode := include "base.getValue" (list . "defaultMode") }}
  {{- if $defaultMode }}
    {{- include "base.field" (list "defaultMode" $defaultMode "base.fileMode") }}
  {{- end }}

  {{- /* items array */ -}}
  {{- $const := include "base.env" "" | fromYaml }}
  {{- $itemsVal := include "base.getValue" (list . "items") | fromYamlArray }}
  {{- $items := list }}
  {{- range $itemsVal }}
    {{- $val := dict }}
    {{- $_val := regexSplit $const.split.space (. | trim) -1 }}
    {{- if eq (len $_val) 2 }}
      {{- $val = dict "key" (index $_val 0) "path" (index $_val 1) }}
    {{- else if eq (len $_val) 3 }}
      {{- $val = dict "key" (index $_val 0) "path" (index $_val 1) "mode" (index $_val 2) }}
    {{- else }}
      {{- fail (printf "definitions.ConfigMapVolumeSource: items ivalid. Values: '%s', format: '(key path [mode], ...)'" .) }}
    {{- end }}
    {{- $items = append $items (include "definitions.KeyToPath" $val | fromYaml) }}
  {{- end }}
  {{- $items = $items | mustUniq | mustCompact }}
  {{- if $items }}
    {{- include "base.field" (list "items" $items "base.slice") }}
  {{- end }}

  {{- /* name string */ -}}
  {{- $name := include "base.getValue" (list . "defaultMode") }}
  {{- if $name }}
    {{- include "base.field" (list "name" $name "base.rfc1035") }}
  {{- end }}

  {{- /* optional bool */ -}}
  {{- $optional := include "base.getValue" (list . "optional") }}
  {{- if $optional }}
    {{- include "base.field" (list "optional" $optional "base.bool") }}
  {{- end }}
{{- end }}
