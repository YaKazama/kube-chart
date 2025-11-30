{{- define "definitions.ISCSIVolumeSource" -}}
  {{- $regex := "^(\\S+)\\s+(\\S+)\\s+(\\d+)\\s+(ext4|xfs|ntfs)\\s*(true|false)\\s*(\\S+)?\\s*(\\S+)\\s*(?:chap\\s*\\((true|false),\\s*(true|false)\\)\\s*)?(?:portals\\s*\\((.*?)\\)\\s*)?(?:(\\S+)\\s*)?$" }}

  {{- $match := regexFindAll $regex . -1 }}
  {{- if not $match }}
    {{- fail (printf "iscsi: error. Values: %s, format: 'targetPortal iqn lun fsType [readOnly] [iscsiInterface] [initiatorName] [chap (chapAuthDiscovery, chapAuthSession)] [portals (ip, ip)] [secretRef]'" .) }}
  {{- end }}

  {{- /* chapAuthDiscovery bool */ -}}
  {{- $chapAuthDiscovery := regexReplaceAll $regex . "${8}" }}
  {{- if $chapAuthDiscovery }}
    {{- include "base.field" (list "chapAuthDiscovery" $chapAuthDiscovery "base.bool") }}
  {{- end }}

  {{- /* chapAuthSession bool */ -}}
  {{- $chapAuthSession := regexReplaceAll $regex . "${9}" }}
  {{- if $chapAuthSession }}
    {{- include "base.field" (list "chapAuthSession" $chapAuthSession "base.bool") }}
  {{- end }}

  {{- /* fsType string */ -}}
  {{- $fsType := regexReplaceAll $regex . "${4}" }}
  {{- include "base.field" (list "fsType" $fsType) }}

  {{- /* initiatorName string */ -}}
  {{- $initiatorName := regexReplaceAll $regex . "${7}" }}
  {{- if $initiatorName }}
    {{- include "base.field" (list "initiatorName" $initiatorName) }}
  {{- end }}

  {{- /* iqn string */ -}}
  {{- $iqn := regexReplaceAll $regex . "${2}" }}
  {{- include "base.field" (list "iqn" $iqn) }}

  {{- /* iscsiInterface string */ -}}
  {{- $iscsiInterface := regexReplaceAll $regex . "${6}" }}
  {{- if $iscsiInterface }}
    {{- include "base.field" (list "iscsiInterface" $iscsiInterface) }}
  {{- end }}

  {{- /* lun int */ -}}
  {{- $lun := regexReplaceAll $regex . "${3}" }}
  {{- include "base.field" (list "lun" $lun) }}

  {{- /* portals string array */ -}}
  {{- $portals := regexReplaceAll $regex . "${10}" }}
  {{- if $portals }}
    {{- include "base.field" (list "portals" (dict "s" $portals "r" ",") "base.slice.cleanup") }}
  {{- end }}

  {{- /* readOnly bool */ -}}
  {{- $readOnly := regexReplaceAll $regex . "${5}" }}
  {{- if $readOnly }}
    {{- include "base.field" (list "readOnly" $readOnly "base.bool") }}
  {{- end }}

  {{- /* secretRef map */ -}}
  {{- $secretRefVal := regexReplaceAll $regex . "${11}" }}
  {{- $secretRef := include "definitions.LocalObjectReference" $secretRefVal | fromYaml }}
  {{- if $secretRef }}
    {{- include "base.field" (list "secretRef" $secretRef "base.map") }}
  {{- end }}

  {{- /* targetPortal string */ -}}
  {{- $targetPortal := regexReplaceAll $regex . "${1}" }}
  {{- include "base.field" (list "targetPortal" $targetPortal) }}
{{- end }}
