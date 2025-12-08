{{- define "definitions.ObjectReference" -}}
  {{- /* apiVersion string */ -}}
  {{- $apiVersion := include "base.getValue" (list . "apiVersion") }}
  {{- if $apiVersion }}
    {{- include "base.field" (list "apiVersion" $apiVersion) }}
  {{- end }}

  {{- /* fieldPath string */ -}}
  {{- $fieldPath := include "base.getValue" (list . "fieldPath") }}
  {{- if $fieldPath }}
    {{- include "base.field" (list "fieldPath" $fieldPath) }}
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
    {{- include "base.field" (list "namespace" $namespace) }}
  {{- end }}

  {{- /* resourceVersion string */ -}}
  {{- $resourceVersion := include "base.getValue" (list . "resourceVersion") }}
  {{- if $resourceVersion }}
    {{- include "base.field" (list "resourceVersion" $resourceVersion) }}
  {{- end }}

  {{- /* uid string */ -}}
  {{- $uid := include "base.getValue" (list . "uid") }}
  {{- if $uid }}
    {{- include "base.field" (list "uid" $uid) }}
  {{- end }}
{{- end }}
