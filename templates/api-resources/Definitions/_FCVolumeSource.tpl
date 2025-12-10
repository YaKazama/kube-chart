{{- define "definitions.FCVolumeSource" -}}
    {{- /* fsType string */ -}}
    {{- $fsType := include "base.getValue" (list . "fsType") }}
    {{- $fsTypeAllows := list "ext4" "xfs" "ntfs" }}
    {{- if $fsType }}
      {{- include "base.field" (list "fsType" $fsType "base.string" $fsTypeAllows) }}
    {{- end }}

    {{- /* lun int */ -}}
    {{- $lun := include "base.getValue" (list . "lun") }}
    {{- if $lun }}
      {{- include "base.field" (list "lun" $lun "base.int") }}
    {{- end }}

    {{- /* readOnly bool */ -}}
    {{- $readOnly := include "base.getValue" (list . "readOnly") }}
    {{- if $readOnly }}
      {{- include "base.field" (list "readOnly" $readOnly "base.bool") }}
    {{- end }}

    {{- /* targetWWNs string array */ -}}
    {{- $targetWWNs := include "base.getValue" (list . "targetWWNs") | fromYamlArray }}
    {{- if $targetWWNs }}
      {{- include "base.field" (list "targetWWNs" $targetWWNs "base.slice") }}
    {{- end }}

    {{- /* wwids string array */ -}}
    {{- $wwids := include "base.getValue" (list . "wwids") | fromYamlArray }}
    {{- if $wwids }}
      {{- include "base.field" (list "wwids" $wwids "base.slice") }}
    {{- end }}
{{- end }}
