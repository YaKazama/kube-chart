{{- define "kustomization.PatchesTarget" -}}
  {{- /* group string */ -}}
  {{- $group := include "base.getValue" (list . "group") }}
  {{- if $group }}
    {{- include "base.field" (list "group" $group) }}
  {{- end }}

  {{- /* version string */ -}}
  {{- $version := include "base.getValue" (list . "version") }}
  {{- if $version }}
    {{- include "base.field" (list "version" $version) }}
  {{- end }}

  {{- /* kind string */ -}}
  {{- $kind := include "base.getValue" (list . "kind") }}
  {{- if $kind }}
    {{- include "base.field" (list "kind" $kind) }}
  {{- end }}

  {{- /* name string */ -}}
  {{- $name := include "base.getValue" (list . "name") }}
  {{- if $name }}
    {{- include "base.field" (list "name" $name) }}
  {{- end }}

  {{- /* namespace string */ -}}
  {{- $namespace := include "base.getValue" (list . "namespace") }}
  {{- if $namespace }}
    {{- include "base.field" (list "namespace" $namespace "base.rfc1123") }}
  {{- end }}

  {{- /* labelSelector string */ -}}
  {{- $labelSelector := include "base.getValue" (list . "labelSelector") }}
  {{- if $labelSelector }}
    {{- include "base.field" (list "labelSelector" $labelSelector) }}
  {{- end }}

  {{- /* annotationSelector string */ -}}
  {{- $annotationSelector := include "base.getValue" (list . "annotationSelector") }}
  {{- if $annotationSelector }}
    {{- include "base.field" (list "annotationSelector" $annotationSelector) }}
  {{- end }}
{{- end }}
