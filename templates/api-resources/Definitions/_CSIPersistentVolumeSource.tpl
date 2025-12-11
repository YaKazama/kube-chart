{{- define "definitions.CSIPersistentVolumeSource" -}}
  {{- /* controllerExpandSecretRef map */ -}}
  {{- $controllerExpandSecretRefVal := include "base.getValue" (list . "controllerExpandSecretRef") | fromYaml }}
  {{- if $controllerExpandSecretRefVal }}
    {{- $controllerExpandSecretRef := include "definitions.SecretReference" $controllerExpandSecretRefVal | fromYaml }}
    {{- if $controllerExpandSecretRef }}
      {{- include "base.field" (list "controllerExpandSecretRef" $controllerExpandSecretRef "base.map") }}
    {{- end }}
  {{- end }}

  {{- /* controllerPublishSecretRef map */ -}}
  {{- $controllerPublishSecretRefVal := include "base.getValue" (list . "controllerPublishSecretRef") | fromYaml }}
  {{- if $controllerPublishSecretRefVal }}
    {{- $controllerPublishSecretRef := include "definitions.SecretReference" $controllerPublishSecretRefVal | fromYaml }}
    {{- if $controllerPublishSecretRef }}
      {{- include "base.field" (list "controllerPublishSecretRef" $controllerPublishSecretRef "base.map") }}
    {{- end }}
  {{- end }}

  {{- /* driver string */ -}}
  {{- $driver := include "base.getValue" (list . "driver") }}
  {{- if $driver }}
    {{- include "base.field" (list "driver" $driver) }}
  {{- else }}
    {{- fail "definitions.CSIPersistentVolumeSource: driver is required." }}
  {{- end }}

  {{- /* fsType string */ -}}
  {{- $fsType := include "base.getValue" (list . "fsType") }}
  {{- $fsTypeAllows := list "ext4" "xfs" "ntfs" }}
  {{- if $fsType }}
    {{- include "base.field" (list "fsType" $fsType "base.string" $fsTypeAllows) }}
  {{- end }}

  {{- /* nodeExpandSecretRef map */ -}}
  {{- $nodeExpandSecretRefVal := include "base.getValue" (list . "nodeExpandSecretRef") | fromYaml }}
  {{- if $nodeExpandSecretRefVal }}
    {{- $nodeExpandSecretRef := include "definitions.SecretReference" $nodeExpandSecretRefVal | fromYaml }}
    {{- if $nodeExpandSecretRef }}
      {{- include "base.field" (list "nodeExpandSecretRef" $nodeExpandSecretRef "base.map") }}
    {{- end }}
  {{- end }}

  {{- /* nodePublishSecretRef map */ -}}
  {{- $nodePublishSecretRefVal := include "base.getValue" (list . "nodePublishSecretRef") | fromYaml }}
  {{- if $nodePublishSecretRefVal }}
    {{- $nodePublishSecretRef := include "definitions.SecretReference" $nodePublishSecretRefVal | fromYaml }}
    {{- if $nodePublishSecretRef }}
      {{- include "base.field" (list "nodePublishSecretRef" $nodePublishSecretRef "base.map") }}
    {{- end }}
  {{- end }}

  {{- /* nodeStageSecretRef map */ -}}
  {{- $nodeStageSecretRefVal := include "base.getValue" (list . "nodeStageSecretRef") | fromYaml }}
  {{- if $nodeStageSecretRefVal }}
    {{- $nodeStageSecretRef := include "definitions.SecretReference" $nodeStageSecretRefVal | fromYaml }}
    {{- if $nodeStageSecretRef }}
      {{- include "base.field" (list "nodeStageSecretRef" $nodeStageSecretRef "base.map") }}
    {{- end }}
  {{- end }}

  {{- /* readOnly bool */ -}}
  {{- $readOnly := include "base.getValue" (list . "readOnly") }}
  {{- if $readOnly }}
    {{- include "base.field" (list "readOnly" $readOnly "base.bool") }}
  {{- end }}

  {{- /* volumeAttributes object/map */ -}}
  {{- $volumeAttributes := include "base.getValue" (list . "volumeAttributes") | fromYaml }}
  {{- if $volumeAttributes }}
    {{- include "base.field" (list "volumeAttributes" $volumeAttributes "base.map") }}
  {{- end }}

  {{- /* volumeHandle string */ -}}
  {{- $volumeHandle := include "base.getValue" (list . "volumeHandle") }}
  {{- if $volumeHandle }}
    {{- include "base.field" (list "volumeHandle" $volumeHandle) }}
  {{- end }}
{{- end }}
