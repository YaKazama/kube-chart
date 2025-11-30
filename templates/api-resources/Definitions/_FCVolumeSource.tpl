{{- define "definitions.FCVolumeSource" -}}
  {{- $regex1 := "^targetWWNs\\s*\\((.*?)\\)\\s+(\\d+)\\s+(ext4|xfs|ntfs)\\s*(true|false)?$" }}
  {{- $regex2 := "^wwids\\s*\\((.*?)\\)\\s+(ext4|xfs|ntfs)\\s*(true|false)?$" }}

  {{- $match1 := regexFindAll $regex1 . -1 }}
  {{- $match2 := regexFindAll $regex2 . -1 }}
  {{- if $match1 }}
    {{- /* fsType string */ -}}
    {{- $fsType := regexReplaceAll $regex1 . "${3}" }}
    {{- include "base.field" (list "fsType" $fsType) }}

    {{- /* lun int */ -}}
    {{- $lun := regexReplaceAll $regex1 . "${2}" }}
    {{- include "base.field" (list "lun" $lun "base.int") }}

    {{- /* readOnly bool */ -}}
    {{- $readOnly := regexReplaceAll $regex1 . "${4}" }}
    {{- if $readOnly }}
      {{- include "base.field" (list "readOnly" $readOnly "base.bool") }}
    {{- end }}

    {{- /* targetWWNs string array */ -}}
    {{- $targetWWNs := regexReplaceAll $regex1 . "${1}" }}
    {{- include "base.field" (list "targetWWNs" (dict "s" $targetWWNs) "base.slice.cleanup") }}

  {{- else if $match2 }}
    {{- /* fsType string */ -}}
    {{- $fsType := regexReplaceAll $regex2 . "${2}" }}
    {{- include "base.field" (list "fsType" $fsType) }}

    {{- /* readOnly bool */ -}}
    {{- $readOnly := regexReplaceAll $regex2 . "${3}" }}
    {{- if $readOnly }}
      {{- include "base.field" (list "readOnly" $readOnly "base.bool") }}
    {{- end }}

    {{- /* wwids string array */ -}}
    {{- $wwids := regexReplaceAll $regex2 . "${1}" }}
    {{- include "base.field" (list "wwids" (dict "s" $wwids) "base.slice.cleanup") }}

  {{- else }}
    {{- fail (printf "fc: error. Values: %s, format: 'targetWWNs (wwn1, wwn2) lun fsType [readOnly]' or 'wwids (wid1, wid2) fsType [readOnly]'" .) }}
  {{- end }}
{{- end }}
