{{- define "definitions.ConfigMapVolumeSource" -}}
  {{- $regex := "^([a-z]\\w+)\\s*(true|false)?\\s*(\\d+)?\\s*(?:items\\s*\\((.*?)\\))?$" }}

  {{- $match := regexFindAll $regex . -1 }}
  {{- if not $match }}
    {{- fail (printf "configMap: error. Values: %s, format: 'name [optional] [defaultMode] [items (key path [mode], ...)]'" .) }}
  {{- end }}

  {{- /* defaultMode int */ -}}
  {{- $defaultModeVal := regexReplaceAll $regex . "${3}" | trim }}
  {{- if $defaultModeVal }}
    {{- $defaultMode := include "base.fileMode" $defaultModeVal }}
    {{- if $defaultMode }}
      {{- include "base.field" (list "defaultMode" $defaultMode) }}
    {{- end }}
  {{- end }}

  {{- /* items */ -}}
  {{- $itemsVal := regexReplaceAll $regex . "${4}" | trim }}
  {{- if $itemsVal }}
    {{- $_itemsVal := regexSplit "," $itemsVal -1 }}
    {{- $items := list }}
    {{- range $_itemsVal }}
      {{- $val := dict }}
      {{- $_val := regexSplit " " (. | trim) -1 }}
      {{- if eq (len $_val) 2 }}
        {{- $_ := set $val "key" (index $_val 0) }}
        {{- $_ := set $val "path" (index $_val 1) }}
      {{- else if eq (len $_val) 3 }}
        {{- $_ := set $val "key" (index $_val 0) }}
        {{- $_ := set $val "path" (index $_val 1) }}
        {{- $_ := set $val "mode" (index $_val 2) }}
      {{- else }}
        {{- fail (printf "configMap: items ivalid. Values: '%s', format: '(key path [mode], ...)'" .) }}
      {{- end }}
      {{- $items = append $items (include "definitions.KeyToPath" $val | fromYaml) }}
    {{- end }}
    {{- $items = $items | mustUniq | mustCompact }}
    {{- if $items }}
      {{- include "base.field" (list "items" $items "base.slice") }}
    {{- end }}
  {{- end }}

  {{- /* name string */ -}}
  {{- $nameVal := regexReplaceAll $regex . "${1}" | trim | lower }}
  {{- $name := include "base.string" $nameVal }}
  {{- if empty $name }}
    {{- fail "configMap: name cannot be empty" }}
  {{- end }}
  {{- include "base.field" (list "name" $name) }}

  {{- /* optional */ -}}
  {{- $optionalVal := regexReplaceAll $regex . "${2}" }}
  {{- $optional := include "base.bool" $optionalVal }}
  {{- if not (eq $optional "false") }}
    {{- include "base.field" (list "optional" $optional "base.bool") }}
  {{- end }}
{{- end }}
