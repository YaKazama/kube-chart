{{- define "definitions.ObjectMeta" -}}
  {{- $_ := set . "_pkind" (get . "_kind") }}

  {{- /* annotations */ -}}
  {{- if not (eq ._pkind "PodTemplateSpec") }}
    {{- $anno := include "base.getValue" (list . "annotations") | fromYaml }}
    {{- if $anno }}
      {{- include "base.field" (list "annotations" $anno "base.map") }}
    {{- end }}
  {{- end }}

  {{- /* labels */ -}}
  {{- $labels := include "base.getValue" (list . "labels") | fromYaml }}
  {{- $isHelmLabels := include "base.getValue" (list . "helmLabels") }}
  {{- if $isHelmLabels }}
    {{- $labels = mustMerge $labels (include "base.helmLabels" . | fromYaml) }}
  {{- end }}
  {{- /* 默认增加 name */ -}}
  {{- $name := include "base.name" . }}
  {{- if $name }}
    {{- $labels = mustMerge $labels (include "base.field" (list "name" $name) | fromYaml) }}
  {{- end }}
  {{- if $labels }}
    {{- include "base.field" (list "labels" $labels "base.map") }}
  {{- end }}

  {{- /* name */ -}}
  {{- if not (eq ._pkind "PodTemplateSpec") }}
    {{- $name := include "base.name" . }}
    {{- if $name }}
      {{- include "base.field" (list "name" $name) }}
    {{- end }}
  {{- end }}

  {{- /* namespace */ -}}
  {{- if not (eq ._pkind "PodTemplateSpec") }}
    {{- $namespace := include "base.namespace" . }}
    {{- if $namespace }}
      {{- include "base.field" (list "namespace" $namespace) }}
    {{- end }}
  {{- end }}
{{- end }}
