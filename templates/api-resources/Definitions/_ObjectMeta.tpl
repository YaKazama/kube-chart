{{- define "definitions.ObjectMeta" -}}
  {{- /* 取值顺序 _pkind > _kind */ -}}
  {{- /* _pkind 大部分时候应该为空值，在 StatefulSetSpec 调用 PersistentVolumeClaim 时会被设置为 StatefulSetSpec */ -}}
  {{- $_kind := coalesce (get . "_pkind") (get . "_kind") }}

  {{- /* annotations map */ -}}
  {{- if not (or (eq $_kind "PodTemplateSpec") (eq $_kind "JobTemplateSpec") (eq $_kind "StatefulSetSpec") (eq $_kind "Namespace")) }}
    {{- $annotations := include "base.getValue" (list . "annotations") | fromYaml }}
    {{- if $annotations }}
      {{- include "base.field" (list "annotations" $annotations "base.map") }}
    {{- end }}
  {{- end }}

  {{- /* labels map */ -}}
  {{- if not (or (eq $_kind "StatefulSetSpec")) }}
    {{- $labels := include "base.getValue" (list . "labels") | fromYaml }}
    {{- $isHelmLabels := include "base.getValue" (list . "helmLabels") }}
    {{- if $isHelmLabels }}
      {{- $labels = mustMerge $labels (include "base.helmLabels" . | fromYaml) }}
    {{- end }}
    {{- if $labels }}
      {{- include "base.field" (list "labels" $labels "base.map") }}
    {{- end }}
  {{- end }}

  {{- /* name string */ -}}
  {{- if not (or (eq $_kind "PodTemplateSpec") (eq $_kind "JobTemplateSpec")) }}
    {{- $_name := "" }}
    {{- if or (eq $_kind "ClusterRole") (eq $_kind "Role") (eq $_kind "ClusterRoleBinding") (eq $_kind "RoleBinding") }}
      {{- $_name = include "base.name.rbac" . }}
    {{- else if eq $_kind "APIService" }}
      {{- $_name = include "base.name.apiservice" . }}
    {{- else }}
      {{- $_name = include "base.name" . }}
    {{- end }}
    {{- if $_name }}
      {{- include "base.field" (list "name" $_name) }}
    {{- end }}
  {{- end }}

  {{- /* namespace string */ -}}
  {{- if not (or (eq $_kind "PodTemplateSpec") (eq $_kind "JobTemplateSpec") (eq $_kind "Namespace")) }}
    {{- $namespace := include "base.namespace" . }}
    {{- if $namespace }}
      {{- include "base.field" (list "namespace" $namespace) }}
    {{- end }}
  {{- end }}
{{- end }}
