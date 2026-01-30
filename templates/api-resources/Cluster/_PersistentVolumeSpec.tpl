{{- define "cluster.PersistentVolumeSpec" -}}
  {{- /* accessModes string array */ -}}
  {{- $accessModes := include "base.getValue" (list . "accessModes") | fromYamlArray }}
  {{- $accessModesAllows := list "ReadWriteOnce" "ReadOnlyMany" "ReadWriteMany" "ReadWriteOncePod" }}
  {{- if $accessModes }}
    {{- if not (has $accessModes $accessModesAllows) }}
      {{- fail (printf "cluster.PersistentVolumeSpec: accessModes '%s' invalid" $accessModes) }}
    {{- end }}
    {{- include "base.field" (list "accessModes" $accessModes "base.slice") }}
  {{- end }}

  {{- /* capacity object/map */ -}}
  {{- $capacity := include "base.getValue" (list . "capacity") | fromYaml }}
  {{- if $capacity }}
    {{- include "base.field" (list "capacity" $capacity "base.map") }}
  {{- end }}

  {{- /* claimRef map */ -}}
  {{- $claimRefVal := include "base.getValue" (list . "claimRef") | fromYaml }}
  {{- if $claimRefVal }}
    {{- $claimRef := include "definitions.ObjectReference" $claimRefVal | fromYaml }}
    {{- if $claimRef }}
      {{- include "base.field" (list "claimRef" $claimRef "base.map") }}
    {{- end }}
  {{- end }}

  {{- /* csi map */ -}}
  {{- $csiVal := include "base.getValue" (list . "csi") | fromYaml }}
  {{- if $csiVal }}
    {{- $csi := include "definitions.CSIPersistentVolumeSource" $csiVal | fromYaml }}
    {{- if $csi }}
      {{- include "base.field" (list "csi" $csi "base.map") }}
    {{- end }}
  {{- end }}

  {{- /* fc map */ -}}
  {{- $fcVal := include "base.getValue" (list . "fc") | fromYaml }}
  {{- if $fcVal }}
    {{- $fc := include "definitions.FCVolumeSource" $fcVal | fromYaml }}
    {{- if $fc }}
      {{- include "base.field" (list "fc" $fc "base.map") }}
    {{- end }}
  {{- end }}

  {{- /* hostPath map */ -}}
  {{- $hostPathVal := include "base.getValue" (list . "hostPath") | fromYaml }}
  {{- if $hostPathVal }}
    {{- $hostPath := include "definitions.HostPathVolumeSource" $hostPathVal | fromYaml }}
    {{- if $hostPath }}
      {{- include "base.field" (list "hostPath" $hostPath "base.map") }}
    {{- end }}
  {{- end }}

  {{- /* iscsi map */ -}}
  {{- $iscsiVal := include "base.getValue" (list . "iscsi") | fromYaml }}
  {{- if $iscsiVal }}
    {{- $iscsi := include "definitions.ISCSIPersistentVolumeSource" $iscsiVal | fromYaml }}
    {{- if $iscsi }}
      {{- include "base.field" (list "iscsi" $iscsi "base.map") }}
    {{- end }}
  {{- end }}

  {{- /* local map */ -}}
  {{- $localVal := include "base.getValue" (list . "local") | fromYaml }}
  {{- if $localVal }}
    {{- $local := include "definitions.LocalVolumeSource" $localVal | fromYaml }}
    {{- if $local }}
      {{- include "base.field" (list "local" $local "base.map") }}
    {{- end }}
  {{- end }}

  {{- /* nfs map */ -}}
  {{- $nfsVal := include "base.getValue" (list . "nfs") | fromYaml }}
  {{- if $nfsVal }}
    {{- $nfs := include "definitions.NFSVolumeSource" $nfsVal | fromYaml }}
    {{- if $nfs }}
      {{- include "base.field" (list "nfs" $nfs "base.map") }}
    {{- end }}
  {{- end }}

  {{- /* nodeAffinity map */ -}}
  {{- $nodeAffinityVal := include "base.getValue" (list . "nodeAffinity") | fromYaml }}
  {{- if $nodeAffinityVal }}
    {{- $nodeAffinity := include "definitions.VolumeNodeAffinity" $nodeAffinityVal | fromYaml }}
    {{- if $nodeAffinity }}
      {{- include "base.field" (list "nodeAffinity" $nodeAffinity "base.map") }}
    {{- end }}
  {{- end }}

  {{- /* mountOptions string array */ -}}
  {{- $mountOptions := include "base.getValue" (list . "mountOptions") | fromYamlArray }}
  {{- if $mountOptions }}
    {{- include "base.field" (list "mountOptions" $mountOptions "base.slice") }}
  {{- end }}

  {{- /* persistentVolumeReclaimPolicy string */ -}}
  {{- $persistentVolumeReclaimPolicy := include "base.getValue" (list . "persistentVolumeReclaimPolicy") }}
  {{- $persistentVolumeReclaimPolicyAllows := list "Delete" "Retain" "Recycle" }}
  {{- if $persistentVolumeReclaimPolicy }}
    {{- include "base.field" (list "persistentVolumeReclaimPolicy" $persistentVolumeReclaimPolicy "base.string" $persistentVolumeReclaimPolicyAllows) }}
  {{- end }}

  {{- /* storageClassName string */ -}}
  {{- $storageClassName := include "base.getValue" (list . "storageClassName") }}
  {{- if $storageClassName }}
    {{- include "base.field" (list "storageClassName" $storageClassName) }}
  {{- end }}

  {{- /* volumeAttributesClassName string */ -}}
  {{- $volumeAttributesClassName := include "base.getValue" (list . "volumeAttributesClassName") }}
  {{- if $volumeAttributesClassName }}
    {{- include "base.field" (list "volumeAttributesClassName" $volumeAttributesClassName) }}
  {{- end }}

  {{- /* volumeMode string */ -}}
  {{- $volumeMode := include "base.getValue" (list . "volumeMode") }}
  {{- $volumeModeAllows := list "Block" "Filesystem" }}
  {{- if $volumeMode }}
    {{- include "base.field" (list "volumeMode" $volumeMode "base.string" $volumeModeAllows) }}
  {{- end }}
{{- end }}
