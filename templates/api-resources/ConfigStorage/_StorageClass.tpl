{{- define "configStorage.StorageClass" -}}
  {{- $_ := set . "_kind" "StorageClass" }}

  {{- include "base.field" (list "apiVersion" "storage.k8s.io/v1") }}
  {{- include "base.field" (list "kind" "StorageClass") }}

  {{- /* metadata map */ -}}
  {{- $metadata := include "definitions.ObjectMeta" . | fromYaml }}
  {{- if $metadata }}
    {{- include "base.field" (list "metadata" $metadata "base.map") }}
  {{- end }}

  {{- /* allowVolumeExpansion bool */ -}}
  {{- $allowVolumeExpansion := include "base.getValue" (list . "allowVolumeExpansion") }}
  {{- if $allowVolumeExpansion }}
    {{- include "base.field" (list "allowVolumeExpansion" $allowVolumeExpansion "base.bool") }}
  {{- end }}

  {{- /* allowedTopologies array */ -}}
  {{- $allowedTopologiesVal := include "base.getValue" (list . "allowedTopologies") | fromYamlArray }}
  {{- $allowedTopologies := list }}
  {{- if $allowedTopologiesVal }}
    {{- $val := dict "matchLabelExpressions" $allowedTopologiesVal }}
    {{- $allowedTopologies = append $allowedTopologies (include "definitions.TopologySelectorTerm" $val | fromYaml) }}
  {{- end }}
  {{- $allowedTopologies = $allowedTopologies | mustUniq | mustCompact }}
  {{- if $allowedTopologies }}
    {{- include "base.field" (list "allowedTopologies" $allowedTopologies "base.slice") }}
  {{- end }}

  {{- /* mountOptions string array */ -}}
  {{- $mountOptions := include "base.getValue" (list . "mountOptions") | fromYamlArray }}
  {{- if $mountOptions }}
    {{- include "base.field" (list "mountOptions" $mountOptions "base.slice") }}
  {{- end }}

  {{- /* parameters object/map */ -}}
  {{- $parameters := include "base.getValue" (list . "parameters") | fromYaml }}
  {{- if $parameters }}
    {{- include "base.field" (list "parameters" $parameters "base.map") }}
  {{- end }}

  {{- /* provisioner string */ -}}
  {{- $provisioner := include "base.getValue" (list . "provisioner") }}
  {{- if $provisioner }}
    {{- include "base.field" (list "provisioner" $provisioner) }}
  {{- end }}

  {{- /* reclaimPolicy string */ -}}
  {{- $reclaimPolicy := include "base.getValue" (list . "reclaimPolicy") }}
  {{- $reclaimPolicyAllows := list "Delete" "Recycle" "Retain" }}
  {{- if $reclaimPolicy }}
    {{- include "base.field" (list "reclaimPolicy" $reclaimPolicy "base.string" $reclaimPolicyAllows) }}
  {{- end }}

  {{- /* volumeBindingMode string */ -}}
  {{- $volumeBindingMode := include "base.getValue" (list . "volumeBindingMode") }}
  {{- $volumeBindingModeAllows := list "Immediate" "WaitForFirstConsumer" }}
  {{- if $volumeBindingMode }}
    {{- include "base.field" (list "volumeBindingMode" $volumeBindingMode "base.string" $volumeBindingModeAllows) }}
  {{- end }}
{{- end }}
