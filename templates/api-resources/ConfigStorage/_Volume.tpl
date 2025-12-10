{{- define "configStorage.Volume" -}}
  {{- /* name string */ -}}
  {{- $name := include "base.getValue" (list . "name") }}
  {{- if $name }}
    {{- include "base.field" (list "name" $name "base.name") }}
  {{- end }}

  {{- $originalValue := "" }}

  {{- $volumeType := include "base.getValue" (list . "volumeType") }}
  {{- $volumeData := include "base.getValue" (list . "volume") }}
  {{- /* configMap map */ -}}
  {{- if or (eq $volumeType "configMap") (eq $volumeType "cm") }}
    {{- $regex := "^([a-z]\\w+)\\s*(true|false)?\\s*(\\d+)?\\s*(?:items\\s*\\((.*?)\\))?$" }}

    {{- $match := regexFindAll $regex $volumeData -1 }}
    {{- if not $match }}
      {{- fail (printf "configStorage.Volume: configMap: invalid. Values: %s, format: 'name [optional] [defaultMode] [items (key path [mode], ...)]'" $volumeData) }}
    {{- end }}

    {{- /* 组装 dict */ -}}
    {{- $name := regexReplaceAll $regex $volumeData "${1}" | trim | lower  }}
    {{- $optional := regexReplaceAll $regex $volumeData "${2}" | trim }}
    {{- $defaultMode := regexReplaceAll $regex $volumeData "${3}" | trim }}
    {{- $items := regexSplit ",\\s*" (regexReplaceAll $regex $volumeData "${4}" | trim) -1 }}
    {{- $val := dict "name" $name "optional" $optional "defaultMode" $defaultMode "items" $items }}

    {{- $cm := include "definitions.ConfigMapVolumeSource" $val | fromYaml }}
    {{- if $cm }}
      {{- include "base.field" (list "configMap" $cm "base.map") }}
    {{- end }}

  {{- /* emptyDir map */ -}}
  {{- else if eq $volumeType "emptyDir" }}
    {{- $regex := "^((?i)Memory)?(?:\\s*((?:\\d+(?:\\.\\d{0,3})?|\\.\\d{1,3})(?:[KMGTPE]i|[mkMGTPE])?))?$" }}

    {{- $medium := regexReplaceAll $regex $volumeData "${1}" | trim | title }}
    {{- $sizeLimit := regexReplaceAll $regex $volumeData "${2}" | trim }}
    {{- $val := dict "medium" $medium "sizeLimit" $sizeLimit }}

    {{- $emptyDir := include "definitions.EmptyDirVolumeSource" $val | fromYaml }}
    {{- include "base.field" (list "emptyDir" $emptyDir "base.map") }}

  {{- /* fc map */ -}}
  {{- else if eq $volumeType "fc" }}
    {{- $regex1 := "^targetWWNs\\s*\\((.*?)\\)\\s+(\\d+)\\s+(ext4|xfs|ntfs)\\s*(true|false)?$" }}
    {{- $regex2 := "^wwids\\s*\\((.*?)\\)\\s+(ext4|xfs|ntfs)\\s*(true|false)?$" }}

    {{- $match1 := regexFindAll $regex1 $volumeData -1 }}
    {{- $match2 := regexFindAll $regex2 $volumeData -1 }}
    {{- if and (not $match1) (not $match2) }}
      {{- fail (printf "configStorage.Volume: fc: invalid. Values: %s, format: 'targetWWNs (wwn1, wwn2) lun fsType [readOnly]' or 'wwids (wid1, wid2) fsType [readOnly]'" $volumeData) }}
    {{- end }}

    {{- $val := dict }}
    {{- if $match1 }}
      {{- $targetWWNs := include "base.slice.cleanup" (dict "s" (regexReplaceAll $regex1 $volumeData "${1}" | trim)) | fromYamlArray }}
      {{- $lun := regexReplaceAll $regex1 $volumeData "${2}" | trim }}
      {{- $fsType := regexReplaceAll $regex1 $volumeData "${3}" | trim }}
      {{- $readOnly := regexReplaceAll $regex1 $volumeData "${4}" | trim }}
      {{- $val = dict "targetWWNs" $targetWWNs "lun" $lun "fsType" $fsType "readOnly" $readOnly }}
    {{- else if $match2 }}
      {{- $wwids := include "base.slice.cleanup" (dict "s" (regexReplaceAll $regex2 $volumeData "${1}" | trim)) | fromYamlArray }}
      {{- $fsType := regexReplaceAll $regex2 $volumeData "${2}" | trim }}
      {{- $readOnly := regexReplaceAll $regex2 $volumeData "${3}" | trim }}
      {{- $val = dict "wwids" $wwids "fsType" $fsType "readOnly" $readOnly }}
    {{- end }}

    {{- $fc := include "definitions.FCVolumeSource" $val | fromYaml }}
    {{- if $fc }}
      {{- include "base.field" (list "fc" $fc "base.map") }}
    {{- end }}

  {{- /* hostPath map */ -}}
  {{- else if eq $volumeType "hostPath" }}
    {{- $regex := "^(\\S+)\\s*(DirectoryOrCreate|Directory|FileOrCreate|File|Socket|CharDevice|BlockDevice)?$" }}

    {{- $match := regexFindAll $regex $volumeData -1 }}
    {{- if not $match }}
      {{- fail (printf "configStorage.Volume: hostPath: invalid. Values: %s, format: 'path [type]'" $volumeData) }}
    {{- end }}

    {{- $path := regexReplaceAll $regex $volumeData "${1}" | trim }}
    {{- $type := regexReplaceAll $regex $volumeData "${2}" | trim }}
    {{- $val := dict "path" $path "type" $type }}

    {{- $hostPath := include "definitions.HostPathVolumeSource" $val | fromYaml }}
    {{- if $hostPath }}
      {{- include "base.field" (list "hostPath" $hostPath "base.map") }}
    {{- end }}

  {{- /* imaage map */ -}}
  {{- else if eq $volumeType "image" }}
    {{- $regex := "^(\\S+)(?:\\s+(Always|Never|IfNotPresent))?$" }}

    {{- $match := regexFindAll $regex $volumeData -1 }}
    {{- if not $match }}
      {{- fail (printf "configStorage.Volume: image: invalid. Values: %s, format: 'reference [pullPolicy]'" .) }}
    {{- end }}

    {{- $reference := regexReplaceAll $regex $volumeData "${1}" | trim }}
    {{- $pullPolicy := regexReplaceAll $regex $volumeData "${2}" | trim }}
    {{- $val := dict "reference" $reference "pullPolicy" $pullPolicy }}

    {{- $image := include "definitions.ImageVolumeSource" $val | fromYaml }}
    {{- if $image }}
      {{- include "base.field" (list "image" $image "base.map") }}
    {{- end }}

  {{- /* iscsi map */ -}}
  {{- else if eq $volumeType "iscsi" }}
    {{- $regex := "^(\\S+)\\s+(\\S+)\\s+(\\d+)\\s+(ext4|xfs|ntfs)(?:\\s+(true|false))(?:\\s+(\\S+))?(?:\\s+(\\S+))(?:\\s+(?:chap\\s*\\((true|false),\\s*(true|false)\\)\\s*))?(?:\\s+(?:portals\\s*\\((.*?)\\)\\s*))?(?:\\s+(\\S+)\\s*)?$" }}

    {{- $match := regexFindAll $regex $volumeData -1 }}
    {{- if not $match }}
      {{- fail (printf "configStorage.Volume: iscsi: invalid. Values: %s, format: 'targetPortal iqn lun fsType [readOnly] [iscsiInterface] [initiatorName] [chap (chapAuthDiscovery, chapAuthSession)] [portals (ip, ip)] [secretRef]'" $volumeData) }}
    {{- end }}

    {{- $targetPortal := regexReplaceAll $regex $volumeData "${1}" | trim }}
    {{- $iqn := regexReplaceAll $regex $volumeData "${2}" | trim }}
    {{- $lun := regexReplaceAll $regex $volumeData "${3}" | trim }}
    {{- $fsType := regexReplaceAll $regex $volumeData "${4}" | trim }}
    {{- $readOnly := regexReplaceAll $regex $volumeData "${5}" | trim }}
    {{- $iscsiInterface := regexReplaceAll $regex $volumeData "${6}" | trim }}
    {{- $initiatorName := regexReplaceAll $regex $volumeData "${7}" | trim }}
    {{- $chapAuthDiscovery := regexReplaceAll $regex $volumeData "${8}" | trim }}
    {{- $chapAuthSession := regexReplaceAll $regex $volumeData "${9}" | trim }}
    {{- $portals := include "base.slice.cleanup" (dict "s" (regexReplaceAll $regex $volumeData "${10}" | trim) "r" ",\\s*") | fromYamlArray }}
    {{- $secretRef := regexReplaceAll $regex $volumeData "${11}" | trim }}
    {{- $val := dict "targetPortal" $targetPortal "iqn" $iqn "lun" $lun "fsType" $fsType "readOnly" $readOnly "iscsiInterface" $iscsiInterface "initiatorName" $initiatorName "chapAuthDiscovery" $chapAuthDiscovery "chapAuthSession" $chapAuthSession "portals" $portals "secretRef" $secretRef }}

    {{- $iscsi := include "definitions.ISCSIVolumeSource" $val | fromYaml }}
    {{- if $iscsi }}
      {{- include "base.field" (list "iscsi" $iscsi "base.map") }}
    {{- end }}

  {{- /* nfs map */ -}}
  {{- else if eq $volumeType "nfs" }}
    {{- $regex := "^(\\S+)(?:\\s+(\\S+))(?:\\s+(true|false))?$" }}

    {{- $match := regexFindAll $regex $volumeData -1 }}
    {{- if not $match }}
      {{- fail (printf "configStorage.Volume: nfs: invalid. Values: %s, format: 'server path [readOnly]'" $volumeData) }}
    {{- end }}

    {{- $server := regexReplaceAll $regex $volumeData "${1}" | trim }}
    {{- $path := regexReplaceAll $regex $volumeData "${2}" | trim }}
    {{- $readOnly := regexReplaceAll $regex $volumeData "${3}" | trim }}
    {{- $val := dict "server" $server "path" $path "readOnly" $readOnly }}

    {{- $nfs := include "definitions.NFSVolumeSource" $val | fromYaml }}
    {{- if $nfs }}
      {{- include "base.field" (list "nfs" $nfs "base.map") }}
    {{- end }}

  {{- /* persistentVolumeClaim map */ -}}
  {{- else if or (eq $volumeType "persistentVolumeClaim") (eq $volumeType "pvc") }}
    {{- $regex := "^(\\S+)(?:\\s+(true|false))?$" }}

    {{- $match := regexFindAll $regex $volumeData -1 }}
    {{- if not $match }}
      {{- fail (printf "configStorage.Volume: persistentVolumeClaim: invalid. Values: %s, format: 'claimName [readOnly]'" $volumeData) }}
    {{- end }}

    {{- $claimName := regexReplaceAll $regex $volumeData "${1}" | trim }}
    {{- $readOnly := regexReplaceAll $regex $volumeData "${2}" | trim }}
    {{- $val := dict "claimName" $claimName "readOnly" $readOnly }}

    {{- $pvc := include "definitions.PersistentVolumeClaimVolumeSource" $val | fromYaml }}
    {{- if $pvc }}
      {{- include "base.field" (list "persistentVolumeClaim" $pvc "base.map") }}
    {{- end }}

  {{- /* secret map */ -}}
  {{- else if eq $volumeType "secret" }}
    {{- $regex := "^([a-z]\\w+)(?:\\s+(true|false))?(?:\\s+(\\d+))?(?:\\s+(?:items\\s*\\((.*?)\\)))?$" }}

    {{- $match := regexFindAll $regex $volumeData -1 }}
    {{- if not $match }}
      {{- fail (printf "configStorage.Volume: secret: invalid. Values: %s, format: 'secretName [optional] [defaultMode] [items (key path [mode], ...)]'" $volumeData) }}
    {{- end }}

    {{- $secretName := regexReplaceAll $regex $volumeData "${1}" | trim | lower }}
    {{- $optional := regexReplaceAll $regex $volumeData "${2}" | trim }}
    {{- $defaultMode := regexReplaceAll $regex $volumeData "${3}" | trim }}
    {{- $items := include "base.slice.cleanup" (dict "s" (regexReplaceAll $regex $volumeData "${4}" | trim) "r" ",\\s*") | fromYamlArray }}
    {{- $val := dict "secretName" $secretName "optional" $optional "defaultMode" $defaultMode "items" $items }}

    {{- $secret := include "definitions.SecretVolumeSource" $val | fromYaml }}
    {{- if $secret }}
      {{- include "base.field" (list "secret" $secret "base.map") }}
    {{- end }}

  {{- /* local map */ -}}
  {{- else if eq $volumeType "local" }}
    {{- $regex := "^(\\S+)(?:\\s+(ext4|xfs|ntfs))?$" }}

    {{- $match := regexFindAll $regex $volumeData -1 }}
    {{- if not $match }}
      {{- fail (printf "configStorage.Volume: local: invalid. Values: %s, format: 'path [fsType]'" $volumeData) }}
    {{- end }}

    {{- $path := regexReplaceAll $regex $volumeData "${1}" | trim }}
    {{- $fsType := regexReplaceAll $regex $volumeData "${2}" | trim }}
    {{- $val := dict "path" $path "fsType" $fsType }}

    {{- $local := include "definitions.LocalVolumeSource" $val | fromYaml }}
    {{- if $local }}
      {{- include "base.field" (list "local" $local "base.map") }}
    {{- end }}
  {{- end }}
{{- end }}
