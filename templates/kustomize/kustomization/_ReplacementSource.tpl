{{- define "kustomization.ReplacementSource" -}}
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

  {{- /* fieldPath string */ -}}
  {{- $fieldPath := include "base.getValue" (list . "fieldPath") }}
  {{- if $fieldPath }}
    {{- include "base.field" (list "fieldPath" $fieldPath) }}
  {{- end }}

  {{- /* options map */ -}}
  {{- $optionsVal := include "base.getValue" (list . "options") | fromYaml }}
  {{- if $optionsVal }}
    {{- $options := include "kustomization.ReplacementSourceOption" $optionsVal | fromYaml }}
    {{- if $options }}
      {{- include "base.field" (list "options" $options "base.map") }}
    {{- end }}
  {{- end }}
{{- end }}
