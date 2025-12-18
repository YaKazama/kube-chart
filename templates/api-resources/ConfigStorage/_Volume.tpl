{{- define "configStorage.Volume" -}}
  {{- $const := include "base.env" "" | fromYaml }}

  {{- /* name string */ -}}
  {{- $name := include "base.getValue" (list . "name") }}
  {{- if $name }}
    {{- include "base.field" (list "name" $name "base.rfc1123") }}
  {{- end }}

  {{- $volumeType := include "base.getValue" (list . "volumeType") }}
  {{- $volumeData := include "base.getValue" (list . "volumeData") }}
  {{- /* configMap map */ -}}
  {{- if or (eq $volumeType "configMap") (eq $volumeType "cm") }}
    {{- $match := regexFindAll $const.k8s.volume.configMap $volumeData -1 }}
    {{- if not $match }}
      {{- fail (printf "configStorage.Volume: configMap: invalid. Values: %s, format: 'name [optional] [defaultMode] [items (key path [mode], ...)]'" $volumeData) }}
    {{- end }}

    {{- /* 组装 dict */ -}}
    {{- $name := regexReplaceAll $const.k8s.volume.configMap $volumeData "${1}" | trim | lower  }}
    {{- $optional := regexReplaceAll $const.k8s.volume.configMap $volumeData "${2}" | trim }}
    {{- $defaultMode := regexReplaceAll $const.k8s.volume.configMap $volumeData "${3}" | trim }}
    {{- $items := regexSplit $const.split.comma (regexReplaceAll $const.k8s.volume.configMap $volumeData "${4}" | trim) -1 }}
    {{- $val := dict "name" $name "optional" $optional "defaultMode" $defaultMode "items" $items }}

    {{- $cm := include "definitions.ConfigMapVolumeSource" $val | fromYaml }}
    {{- if $cm }}
      {{- include "base.field" (list "configMap" $cm "base.map") }}
    {{- end }}

  {{- /* emptyDir map */ -}}
  {{- else if eq $volumeType "emptyDir" }}
    {{- $medium := regexReplaceAll $const.k8s.volume.emptyDir $volumeData "${1}" | trim | title }}
    {{- $sizeLimit := regexReplaceAll $const.k8s.volume.emptyDir $volumeData "${2}" | trim }}
    {{- $val := dict "medium" $medium "sizeLimit" $sizeLimit }}

    {{- $emptyDir := include "definitions.EmptyDirVolumeSource" $val | fromYaml }}
    {{- include "base.field" (list "emptyDir" $emptyDir "base.map") }}

  {{- /* fc map */ -}}
  {{- else if eq $volumeType "fc" }}
    {{- $match1 := regexFindAll $const.k8s.volume.fc0 $volumeData -1 }}
    {{- $match2 := regexFindAll $const.k8s.volume.fc1 $volumeData -1 }}
    {{- if and (not $match1) (not $match2) }}
      {{- fail (printf "configStorage.Volume: fc: invalid. Values: %s, format: 'targetWWNs (wwn1, wwn2) lun fsType [readOnly]' or 'wwids (wid1, wid2) fsType [readOnly]'" $volumeData) }}
    {{- end }}

    {{- $val := dict }}
    {{- if $match1 }}
      {{- $targetWWNs := include "base.slice.cleanup" (dict "s" (regexReplaceAll $const.k8s.volume.fc0 $volumeData "${1}" | trim)) | fromYamlArray }}
      {{- $lun := regexReplaceAll $const.k8s.volume.fc0 $volumeData "${2}" | trim }}
      {{- $fsType := regexReplaceAll $const.k8s.volume.fc0 $volumeData "${3}" | trim }}
      {{- $readOnly := regexReplaceAll $const.k8s.volume.fc0 $volumeData "${4}" | trim }}
      {{- $val = dict "targetWWNs" $targetWWNs "lun" $lun "fsType" $fsType "readOnly" $readOnly }}
    {{- else if $match2 }}
      {{- $wwids := include "base.slice.cleanup" (dict "s" (regexReplaceAll $const.k8s.volume.fc1 $volumeData "${1}" | trim)) | fromYamlArray }}
      {{- $fsType := regexReplaceAll $const.k8s.volume.fc1 $volumeData "${2}" | trim }}
      {{- $readOnly := regexReplaceAll $const.k8s.volume.fc1 $volumeData "${3}" | trim }}
      {{- $val = dict "wwids" $wwids "fsType" $fsType "readOnly" $readOnly }}
    {{- end }}

    {{- $fc := include "definitions.FCVolumeSource" $val | fromYaml }}
    {{- if $fc }}
      {{- include "base.field" (list "fc" $fc "base.map") }}
    {{- end }}

  {{- /* hostPath map */ -}}
  {{- else if eq $volumeType "hostPath" }}
    {{- $match := regexFindAll $const.k8s.volume.hostPath $volumeData -1 }}
    {{- if not $match }}
      {{- fail (printf "configStorage.Volume: hostPath: invalid. Values: %s, format: 'path [type]'" $volumeData) }}
    {{- end }}

    {{- $path := regexReplaceAll $const.k8s.volume.hostPath $volumeData "${1}" | trim }}
    {{- $type := regexReplaceAll $const.k8s.volume.hostPath $volumeData "${2}" | trim }}
    {{- $val := dict "path" $path "type" $type }}

    {{- $hostPath := include "definitions.HostPathVolumeSource" $val | fromYaml }}
    {{- if $hostPath }}
      {{- include "base.field" (list "hostPath" $hostPath "base.map") }}
    {{- end }}

  {{- /* imaage map */ -}}
  {{- else if eq $volumeType "image" }}
    {{- $match := regexFindAll $const.k8s.volume.image $volumeData -1 }}
    {{- if not $match }}
      {{- fail (printf "configStorage.Volume: image: invalid. Values: %s, format: 'reference [pullPolicy]'" .) }}
    {{- end }}

    {{- $reference := regexReplaceAll $const.k8s.volume.image $volumeData "${1}" | trim }}
    {{- $pullPolicy := regexReplaceAll $const.k8s.volume.image $volumeData "${2}" | trim }}
    {{- $val := dict "reference" $reference "pullPolicy" $pullPolicy }}

    {{- $image := include "definitions.ImageVolumeSource" $val | fromYaml }}
    {{- if $image }}
      {{- include "base.field" (list "image" $image "base.map") }}
    {{- end }}

  {{- /* iscsi map */ -}}
  {{- else if eq $volumeType "iscsi" }}
    {{- $match := regexFindAll $const.k8s.volume.iscsi $volumeData -1 }}
    {{- if not $match }}
      {{- fail (printf "configStorage.Volume: iscsi: invalid. Values: %s, format: 'targetPortal iqn lun fsType [readOnly] [iscsiInterface] [initiatorName] [chap (chapAuthDiscovery, chapAuthSession)] [portals (ip, ip)] [secretRef]'" $volumeData) }}
    {{- end }}

    {{- $targetPortal := regexReplaceAll $const.k8s.volume.iscsi $volumeData "${1}" | trim }}
    {{- $iqn := regexReplaceAll $const.k8s.volume.iscsi $volumeData "${2}" | trim }}
    {{- $lun := regexReplaceAll $const.k8s.volume.iscsi $volumeData "${3}" | trim }}
    {{- $fsType := regexReplaceAll $const.k8s.volume.iscsi $volumeData "${4}" | trim }}
    {{- $readOnly := regexReplaceAll $const.k8s.volume.iscsi $volumeData "${5}" | trim }}
    {{- $iscsiInterface := regexReplaceAll $const.k8s.volume.iscsi $volumeData "${6}" | trim }}
    {{- $initiatorName := regexReplaceAll $const.k8s.volume.iscsi $volumeData "${7}" | trim }}
    {{- $chapAuthDiscovery := regexReplaceAll $const.k8s.volume.iscsi $volumeData "${8}" | trim }}
    {{- $chapAuthSession := regexReplaceAll $const.k8s.volume.iscsi $volumeData "${9}" | trim }}
    {{- $portals := include "base.slice.cleanup" (dict "s" (regexReplaceAll $const.k8s.volume.iscsi $volumeData "${10}" | trim) "r" $const.split.comma) | fromYamlArray }}
    {{- $secretRef := regexReplaceAll $const.k8s.volume.iscsi $volumeData "${11}" | trim }}
    {{- $val := dict "targetPortal" $targetPortal "iqn" $iqn "lun" $lun "fsType" $fsType "readOnly" $readOnly "iscsiInterface" $iscsiInterface "initiatorName" $initiatorName "chapAuthDiscovery" $chapAuthDiscovery "chapAuthSession" $chapAuthSession "portals" $portals "secretRef" $secretRef }}

    {{- $iscsi := include "definitions.ISCSIVolumeSource" $val | fromYaml }}
    {{- if $iscsi }}
      {{- include "base.field" (list "iscsi" $iscsi "base.map") }}
    {{- end }}

  {{- /* nfs map */ -}}
  {{- else if eq $volumeType "nfs" }}
    {{- $match := regexFindAll $const.k8s.volume.nfs $volumeData -1 }}
    {{- if not $match }}
      {{- fail (printf "configStorage.Volume: nfs: invalid. Values: %s, format: 'server path [readOnly]'" $volumeData) }}
    {{- end }}

    {{- $server := regexReplaceAll $const.k8s.volume.nfs $volumeData "${1}" | trim }}
    {{- $path := regexReplaceAll $const.k8s.volume.nfs $volumeData "${2}" | trim }}
    {{- $readOnly := regexReplaceAll $const.k8s.volume.nfs $volumeData "${3}" | trim }}
    {{- $val := dict "server" $server "path" $path "readOnly" $readOnly }}

    {{- $nfs := include "definitions.NFSVolumeSource" $val | fromYaml }}
    {{- if $nfs }}
      {{- include "base.field" (list "nfs" $nfs "base.map") }}
    {{- end }}

  {{- /* persistentVolumeClaim map */ -}}
  {{- else if or (eq $volumeType "persistentVolumeClaim") (eq $volumeType "pvc") }}
    {{- $match := regexFindAll $const.k8s.volume.pvc $volumeData -1 }}
    {{- if not $match }}
      {{- fail (printf "configStorage.Volume: persistentVolumeClaim: invalid. Values: %s, format: 'claimName [readOnly]'" $volumeData) }}
    {{- end }}

    {{- $claimName := regexReplaceAll $const.k8s.volume.pvc $volumeData "${1}" | trim }}
    {{- $readOnly := regexReplaceAll $const.k8s.volume.pvc $volumeData "${2}" | trim }}
    {{- $val := dict "claimName" $claimName "readOnly" $readOnly }}

    {{- $pvc := include "definitions.PersistentVolumeClaimVolumeSource" $val | fromYaml }}
    {{- if $pvc }}
      {{- include "base.field" (list "persistentVolumeClaim" $pvc "base.map") }}
    {{- end }}

  {{- /* secret map */ -}}
  {{- else if eq $volumeType "secret" }}
    {{- $match := regexFindAll $const.k8s.volume.secret $volumeData -1 }}
    {{- if not $match }}
      {{- fail (printf "configStorage.Volume: secret: invalid. Values: %s, format: 'secretName [optional] [defaultMode] [items (key path [mode], ...)]'" $volumeData) }}
    {{- end }}

    {{- $secretName := regexReplaceAll $const.k8s.volume.secret $volumeData "${1}" | trim | lower }}
    {{- $optional := regexReplaceAll $const.k8s.volume.secret $volumeData "${2}" | trim }}
    {{- $defaultMode := regexReplaceAll $const.k8s.volume.secret $volumeData "${3}" | trim }}
    {{- $items := include "base.slice.cleanup" (dict "s" (regexReplaceAll $const.k8s.volume.secret $volumeData "${4}" | trim) "r" $const.split.comma) | fromYamlArray }}
    {{- $val := dict "secretName" $secretName "optional" $optional "defaultMode" $defaultMode "items" $items }}

    {{- $secret := include "definitions.SecretVolumeSource" $val | fromYaml }}
    {{- if $secret }}
      {{- include "base.field" (list "secret" $secret "base.map") }}
    {{- end }}

  {{- /* local map */ -}}
  {{- else if eq $volumeType "local" }}
    {{- $match := regexFindAll $const.k8s.volume.local $volumeData -1 }}
    {{- if not $match }}
      {{- fail (printf "configStorage.Volume: local: invalid. Values: %s, format: 'path [fsType]'" $volumeData) }}
    {{- end }}

    {{- $path := regexReplaceAll $const.k8s.volume.local $volumeData "${1}" | trim }}
    {{- $fsType := regexReplaceAll $const.k8s.volume.local $volumeData "${2}" | trim }}
    {{- $val := dict "path" $path "fsType" $fsType }}

    {{- $local := include "definitions.LocalVolumeSource" $val | fromYaml }}
    {{- if $local }}
      {{- include "base.field" (list "local" $local "base.map") }}
    {{- end }}
  {{- end }}
{{- end }}
