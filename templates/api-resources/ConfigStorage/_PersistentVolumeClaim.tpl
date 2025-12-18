{{- define "configStorage.PersistentVolumeClaim" -}}
  # 兼容独立执行、StatefulSetSpec 调用
  {{- $_pkind := get . "_kind" }}
  {{- if empty $_pkind }}
    {{- $_ := set . "_kind" "PersistentVolumeClaim" }}
  {{- end }}

  {{- /* metadata map */ -}}
  {{- $metadata := include "definitions.ObjectMeta" . | fromYaml }}
  {{- if $metadata }}
    {{- include "base.field" (list "metadata" $metadata "base.map") }}
  {{- end }}

  {{- /* spec map */ -}}
  {{- $spec := include "configStorage.PersistentVolumeClaimSpec" . | fromYaml }}
  {{- if $spec }}
    {{- include "base.field" (list "spec" $spec "base.map") }}
  {{- end }}
{{- end }}
