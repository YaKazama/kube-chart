{{- define "definitions.ObjectMeta" -}}
  {{- $_pkind := get . "_kind" }}

  {{- /* annotations */ -}}
  {{- if not (or (eq $_pkind "PodTemplateSpec") (eq $_pkind "JobTemplateSpec") (eq $_pkind "StatefulSetSpec")) }}
    {{- $annotations := include "base.getValue" (list . "annotations") | fromYaml }}
    {{- if $annotations }}
      {{- include "base.field" (list "annotations" $annotations "base.map") }}
    {{- end }}
  {{- end }}

  {{- /* labels */ -}}
  {{- if not (eq $_pkind "StatefulSetSpec") }}
    {{- $labels := include "base.getValue" (list . "labels") | fromYaml }}
    {{- $isHelmLabels := include "base.getValue" (list . "helmLabels") }}
    {{- if $isHelmLabels }}
      {{- $labels = mustMerge $labels (include "base.helmLabels" . | fromYaml) }}
    {{- end }}
    {{- if $labels }}
      {{- include "base.field" (list "labels" $labels "base.map") }}
    {{- end }}
  {{- end }}

  {{- /* name */ -}}
  {{- if not (or (eq $_pkind "PodTemplateSpec") (eq $_pkind "JobTemplateSpec"))  }}
    {{- $name := include "base.name" . }}
    {{- if $name }}
      {{- include "base.field" (list "name" $name) }}
    {{- end }}
  {{- end }}

  {{- /* namespace */ -}}
  {{- if not (or (eq $_pkind "PodTemplateSpec") (eq $_pkind "JobTemplateSpec")) }}
    {{- $namespace := include "base.namespace" . }}
    {{- if $namespace }}
      {{- include "base.field" (list "namespace" $namespace) }}
    {{- end }}
  {{- end }}
{{- end }}
