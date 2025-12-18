{{- define "definitions.ISCSIVolumeSource" -}}
  {{- /* chapAuthDiscovery bool */ -}}
  {{- $chapAuthDiscovery := include "base.getValue" (list . "chapAuthDiscovery" "toString") }}
  {{- if $chapAuthDiscovery }}
    {{- include "base.field" (list "chapAuthDiscovery" $chapAuthDiscovery "base.bool") }}
  {{- end }}

  {{- /* chapAuthSession bool */ -}}
  {{- $chapAuthSession := include "base.getValue" (list . "chapAuthSession" "toString") }}
  {{- if $chapAuthSession }}
    {{- include "base.field" (list "chapAuthSession" $chapAuthSession "base.bool") }}
  {{- end }}

  {{- /* fsType string */ -}}
  {{- $fsType := include "base.getValue" (list . "fsType") }}
  {{- $fsTypeAllows := list "ext4" "xfs" "ntfs" }}
  {{- if $fsType }}
    {{- include "base.field" (list "fsType" $fsType "base.string" $fsTypeAllows) }}
  {{- end }}

  {{- /* initiatorName string */ -}}
  {{- $initiatorName := include "base.getValue" (list . "initiatorName") }}
  {{- if $initiatorName }}
    {{- include "base.field" (list "initiatorName" $initiatorName) }}
  {{- end }}

  {{- /* iqn string */ -}}
  {{- $iqn := include "base.getValue" (list . "iqn") }}
  {{- if $iqn }}
    {{- include "base.field" (list "iqn" $iqn) }}
  {{- end }}

  {{- /* iscsiInterface string */ -}}
  {{- $iscsiInterface := include "base.getValue" (list . "iscsiInterface") }}
  {{- if $iscsiInterface }}
    {{- include "base.field" (list "iscsiInterface" $iscsiInterface) }}
  {{- end }}

  {{- /* lun int */ -}}
  {{- $lun := include "base.getValue" (list . "lun") }}
  {{- if $lun }}
    {{- include "base.field" (list "lun" $lun "base.int") }}
  {{- end }}

  {{- /* portals string array */ -}}
  {{- $portals := include "base.getValue" (list . "portals") | fromYamlArray }}
  {{- if $portals }}
    {{- include "base.field" (list "portals" $portals "base.slice") }}
  {{- end }}

  {{- /* readOnly bool */ -}}
  {{- $readOnly := include "base.getValue" (list . "readOnly") }}
  {{- if $readOnly }}
    {{- include "base.field" (list "readOnly" $readOnly "base.bool") }}
  {{- end }}

  {{- /* secretRef map */ -}}
  {{- $secretRefVal := include "base.getValue" (list . "secretRef") }}
  {{- $val := dict "name" $secretRefVal }}
  {{- $secretRef := include "definitions.LocalObjectReference" $val | fromYaml }}
  {{- if $secretRef }}
    {{- include "base.field" (list "secretRef" $secretRef "base.map") }}
  {{- end }}

  {{- /* targetPortal string */ -}}
  {{- $targetPortal := include "base.getValue" (list . "targetPortal") }}
  {{- if $targetPortal }}
      {{- include "base.field" (list "targetPortal" $targetPortal) }}
  {{- end }}
{{- end }}
