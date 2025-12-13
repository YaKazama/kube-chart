{{- define "definitions.SecretVolumeSource" -}}
  {{- /* defaultMode int */ -}}
  {{- $defaultMode := include "base.getValue" (list . "defaultMode") }}
  {{- if $defaultMode }}
    {{- include "base.field" (list "defaultMode" $defaultMode "base.fileMode") }}
  {{- end }}

  {{- /* items */ -}}
  {{- $const := include "base.env" "" | fromYaml }}
  {{- $itemsVal := include "base.getValue" (list . "items") | fromYamlArray }}
  {{- $items := list }}
  {{- range $itemsVal }}
    {{- $val := dict }}
    {{- $_val := regexSplit $const.regexSplit (. | trim) -1 }}
    {{- if eq (len $_val) 2 }}
      {{- $val = dict "key" (index $_val 0) "path" (index $_val 1) }}
    {{- else if eq (len $_val) 3 }}
      {{- $val = dict "key" (index $_val 0) "path" (index $_val 1) "mode" (index $_val 2) }}
    {{- else }}
      {{- fail (printf "definitions.SecretVolumeSource: items ivalid. Values: '%s', format: '(key path [mode], ...)'" .) }}
    {{- end }}
    {{- $items = append $items (include "definitions.KeyToPath" $val | fromYaml) }}
  {{- end }}
  {{- $items = $items | mustUniq | mustCompact }}
  {{- if $items }}
    {{- include "base.field" (list "items" $items "base.slice") }}
  {{- end }}

  {{- /* secretName string */ -}}
  {{- $secretName := include "base.getValue" (list . "secretName") }}
  {{- if empty $secretName }}
    {{- fail "definitions.SecretVolumeSource: secretName cannot be empty" }}
  {{- end }}
  {{- if $secretName }}
    {{- include "base.field" (list "secretName" $secretName) }}
  {{- end }}

  {{- /* optional */ -}}
  {{- $optional := include "base.getValue" (list . "optional") }}
  {{- if $optional }}
    {{- include "base.field" (list "optional" $optional "base.bool") }}
  {{- end }}
{{- end }}
