{{- define "configStorage.Volume" -}}
  {{- /* name string */ -}}
  {{- $name := include "base.getValue" (list . "name") }}
  {{- if $name }}
    {{- include "base.field" (list "name" $name "base.name") }}
  {{- end }}

  {{- $volumeType := include "base.getValue" (list . "volumeType") }}
  {{- $volumeData := include "base.getValue" (list . "volumeData") }}
  {{- /* configMap map */ -}}
  {{- if or (eq $volumeType "configMap") (eq $volumeType "cm") }}
    {{- $match := regexFindAll $const.regexVolumeConfigMap $volumeData -1 }}
    {{- if not $match }}
      {{- fail (printf "configStorage.Volume: configMap: invalid. Values: %s, format: 'name [optional] [defaultMode] [items (key path [mode], ...)]'" $volumeData) }}
    {{- end }}

    {{- /* 组装 dict */ -}}
    {{- $name := regexReplaceAll $const.regexVolumeConfigMap $volumeData "${1}" | trim | lower  }}
    {{- $optional := regexReplaceAll $const.regexVolumeConfigMap $volumeData "${2}" | trim }}
    {{- $defaultMode := regexReplaceAll $const.regexVolumeConfigMap $volumeData "${3}" | trim }}
    {{- $items := regexSplit $const.regexSplitComma (regexReplaceAll $const.regexVolumeConfigMap $volumeData "${4}" | trim) -1 }}
    {{- $val := dict "name" $name "optional" $optional "defaultMode" $defaultMode "items" $items }}

    {{- $cm := include "definitions.ConfigMapVolumeSource" $val | fromYaml }}
    {{- if $cm }}
      {{- include "base.field" (list "configMap" $cm "base.map") }}
    {{- end }}

  {{- /* emptyDir map */ -}}
  {{- else if eq $volumeType "emptyDir" }}
    {{- $medium := regexReplaceAll $const.regexVolumeEmptyDir $volumeData "${1}" | trim | title }}
    {{- $sizeLimit := regexReplaceAll $const.regexVolumeEmptyDir $volumeData "${2}" | trim }}
    {{- $val := dict "medium" $medium "sizeLimit" $sizeLimit }}

    {{- $emptyDir := include "definitions.EmptyDirVolumeSource" $val | fromYaml }}
    {{- include "base.field" (list "emptyDir" $emptyDir "base.map") }}

  {{- /* fc map */ -}}
  {{- else if eq $volumeType "fc" }}
    {{- $match1 := regexFindAll $const.regexVolumeFC1 $volumeData -1 }}
    {{- $match2 := regexFindAll $const.regexVolumeFC2 $volumeData -1 }}
    {{- if and (not $match1) (not $match2) }}
      {{- fail (printf "configStorage.Volume: fc: invalid. Values: %s, format: 'targetWWNs (wwn1, wwn2) lun fsType [readOnly]' or 'wwids (wid1, wid2) fsType [readOnly]'" $volumeData) }}
    {{- end }}

    {{- $val := dict }}
    {{- if $match1 }}
      {{- $targetWWNs := include "base.slice.cleanup" (dict "s" (regexReplaceAll $const.regexVolumeFC1 $volumeData "${1}" | trim)) | fromYamlArray }}
      {{- $lun := regexReplaceAll $const.regexVolumeFC1 $volumeData "${2}" | trim }}
      {{- $fsType := regexReplaceAll $const.regexVolumeFC1 $volumeData "${3}" | trim }}
      {{- $readOnly := regexReplaceAll $const.regexVolumeFC1 $volumeData "${4}" | trim }}
      {{- $val = dict "targetWWNs" $targetWWNs "lun" $lun "fsType" $fsType "readOnly" $readOnly }}
    {{- else if $match2 }}
      {{- $wwids := include "base.slice.cleanup" (dict "s" (regexReplaceAll $const.regexVolumeFC2 $volumeData "${1}" | trim)) | fromYamlArray }}
      {{- $fsType := regexReplaceAll $const.regexVolumeFC2 $volumeData "${2}" | trim }}
      {{- $readOnly := regexReplaceAll $const.regexVolumeFC2 $volumeData "${3}" | trim }}
      {{- $val = dict "wwids" $wwids "fsType" $fsType "readOnly" $readOnly }}
    {{- end }}

    {{- $fc := include "definitions.FCVolumeSource" $val | fromYaml }}
    {{- if $fc }}
      {{- include "base.field" (list "fc" $fc "base.map") }}
    {{- end }}

  {{- /* hostPath map */ -}}
  {{- else if eq $volumeType "hostPath" }}
    {{- $match := regexFindAll $const.regexVolumeHostPath $volumeData -1 }}
    {{- if not $match }}
      {{- fail (printf "configStorage.Volume: hostPath: invalid. Values: %s, format: 'path [type]'" $volumeData) }}
    {{- end }}

    {{- $path := regexReplaceAll $const.regexVolumeHostPath $volumeData "${1}" | trim }}
    {{- $type := regexReplaceAll $const.regexVolumeHostPath $volumeData "${2}" | trim }}
    {{- $val := dict "path" $path "type" $type }}

    {{- $hostPath := include "definitions.HostPathVolumeSource" $val | fromYaml }}
    {{- if $hostPath }}
      {{- include "base.field" (list "hostPath" $hostPath "base.map") }}
    {{- end }}

  {{- /* imaage map */ -}}
  {{- else if eq $volumeType "image" }}
    {{- $match := regexFindAll $const.Image $volumeData -1 }}
    {{- if not $match }}
      {{- fail (printf "configStorage.Volume: image: invalid. Values: %s, format: 'reference [pullPolicy]'" .) }}
    {{- end }}

    {{- $reference := regexReplaceAll $const.Image $volumeData "${1}" | trim }}
    {{- $pullPolicy := regexReplaceAll $const.Image $volumeData "${2}" | trim }}
    {{- $val := dict "reference" $reference "pullPolicy" $pullPolicy }}

    {{- $image := include "definitions.ImageVolumeSource" $val | fromYaml }}
    {{- if $image }}
      {{- include "base.field" (list "image" $image "base.map") }}
    {{- end }}

  {{- /* iscsi map */ -}}
  {{- else if eq $volumeType "iscsi" }}
    {{- $match := regexFindAll $const.regexVolumeIscsi $volumeData -1 }}
    {{- if not $match }}
      {{- fail (printf "configStorage.Volume: iscsi: invalid. Values: %s, format: 'targetPortal iqn lun fsType [readOnly] [iscsiInterface] [initiatorName] [chap (chapAuthDiscovery, chapAuthSession)] [portals (ip, ip)] [secretRef]'" $volumeData) }}
    {{- end }}

    {{- $targetPortal := regexReplaceAll $const.regexVolumeIscsi $volumeData "${1}" | trim }}
    {{- $iqn := regexReplaceAll $const.regexVolumeIscsi $volumeData "${2}" | trim }}
    {{- $lun := regexReplaceAll $const.regexVolumeIscsi $volumeData "${3}" | trim }}
    {{- $fsType := regexReplaceAll $const.regexVolumeIscsi $volumeData "${4}" | trim }}
    {{- $readOnly := regexReplaceAll $const.regexVolumeIscsi $volumeData "${5}" | trim }}
    {{- $iscsiInterface := regexReplaceAll $const.regexVolumeIscsi $volumeData "${6}" | trim }}
    {{- $initiatorName := regexReplaceAll $const.regexVolumeIscsi $volumeData "${7}" | trim }}
    {{- $chapAuthDiscovery := regexReplaceAll $const.regexVolumeIscsi $volumeData "${8}" | trim }}
    {{- $chapAuthSession := regexReplaceAll $const.regexVolumeIscsi $volumeData "${9}" | trim }}
    {{- $portals := include "base.slice.cleanup" (dict "s" (regexReplaceAll $const.regexVolumeIscsi $volumeData "${10}" | trim) "r" $const.regexSplitComma) | fromYamlArray }}
    {{- $secretRef := regexReplaceAll $const.regexVolumeIscsi $volumeData "${11}" | trim }}
    {{- $val := dict "targetPortal" $targetPortal "iqn" $iqn "lun" $lun "fsType" $fsType "readOnly" $readOnly "iscsiInterface" $iscsiInterface "initiatorName" $initiatorName "chapAuthDiscovery" $chapAuthDiscovery "chapAuthSession" $chapAuthSession "portals" $portals "secretRef" $secretRef }}

    {{- $iscsi := include "definitions.ISCSIVolumeSource" $val | fromYaml }}
    {{- if $iscsi }}
      {{- include "base.field" (list "iscsi" $iscsi "base.map") }}
    {{- end }}

  {{- /* nfs map */ -}}
  {{- else if eq $volumeType "nfs" }}
    {{- $match := regexFindAll $const.regexVolumeNFS $volumeData -1 }}
    {{- if not $match }}
      {{- fail (printf "configStorage.Volume: nfs: invalid. Values: %s, format: 'server path [readOnly]'" $volumeData) }}
    {{- end }}

    {{- $server := regexReplaceAll $const.regexVolumeNFS $volumeData "${1}" | trim }}
    {{- $path := regexReplaceAll $const.regexVolumeNFS $volumeData "${2}" | trim }}
    {{- $readOnly := regexReplaceAll $const.regexVolumeNFS $volumeData "${3}" | trim }}
    {{- $val := dict "server" $server "path" $path "readOnly" $readOnly }}

    {{- $nfs := include "definitions.NFSVolumeSource" $val | fromYaml }}
    {{- if $nfs }}
      {{- include "base.field" (list "nfs" $nfs "base.map") }}
    {{- end }}

  {{- /* persistentVolumeClaim map */ -}}
  {{- else if or (eq $volumeType "persistentVolumeClaim") (eq $volumeType "pvc") }}
    {{- $match := regexFindAll $const.regexVolumePersistentVolumeClaim $volumeData -1 }}
    {{- if not $match }}
      {{- fail (printf "configStorage.Volume: persistentVolumeClaim: invalid. Values: %s, format: 'claimName [readOnly]'" $volumeData) }}
    {{- end }}

    {{- $claimName := regexReplaceAll $const.regexVolumePersistentVolumeClaim $volumeData "${1}" | trim }}
    {{- $readOnly := regexReplaceAll $const.regexVolumePersistentVolumeClaim $volumeData "${2}" | trim }}
    {{- $val := dict "claimName" $claimName "readOnly" $readOnly }}

    {{- $pvc := include "definitions.PersistentVolumeClaimVolumeSource" $val | fromYaml }}
    {{- if $pvc }}
      {{- include "base.field" (list "persistentVolumeClaim" $pvc "base.map") }}
    {{- end }}

  {{- /* secret map */ -}}
  {{- else if eq $volumeType "secret" }}
    {{- $match := regexFindAll $const.regexVolumeSecret $volumeData -1 }}
    {{- if not $match }}
      {{- fail (printf "configStorage.Volume: secret: invalid. Values: %s, format: 'secretName [optional] [defaultMode] [items (key path [mode], ...)]'" $volumeData) }}
    {{- end }}

    {{- $secretName := regexReplaceAll $const.regexVolumeSecret $volumeData "${1}" | trim | lower }}
    {{- $optional := regexReplaceAll $const.regexVolumeSecret $volumeData "${2}" | trim }}
    {{- $defaultMode := regexReplaceAll $const.regexVolumeSecret $volumeData "${3}" | trim }}
    {{- $items := include "base.slice.cleanup" (dict "s" (regexReplaceAll $const.regexVolumeSecret $volumeData "${4}" | trim) "r" $const.regexSplitComma) | fromYamlArray }}
    {{- $val := dict "secretName" $secretName "optional" $optional "defaultMode" $defaultMode "items" $items }}

    {{- $secret := include "definitions.SecretVolumeSource" $val | fromYaml }}
    {{- if $secret }}
      {{- include "base.field" (list "secret" $secret "base.map") }}
    {{- end }}

  {{- /* local map */ -}}
  {{- else if eq $volumeType "local" }}
    {{- $match := regexFindAll $const.regexVolumeLocal $volumeData -1 }}
    {{- if not $match }}
      {{- fail (printf "configStorage.Volume: local: invalid. Values: %s, format: 'path [fsType]'" $volumeData) }}
    {{- end }}

    {{- $path := regexReplaceAll $const.regexVolumeLocal $volumeData "${1}" | trim }}
    {{- $fsType := regexReplaceAll $const.regexVolumeLocal $volumeData "${2}" | trim }}
    {{- $val := dict "path" $path "fsType" $fsType }}

    {{- $local := include "definitions.LocalVolumeSource" $val | fromYaml }}
    {{- if $local }}
      {{- include "base.field" (list "local" $local "base.map") }}
    {{- end }}
  {{- end }}
{{- end }}
