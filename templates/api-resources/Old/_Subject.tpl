{{- define "old.Subject" -}}
  {{- /* kind string */ -}}
  {{- $kind := include "base.getValue" (list . "kind") }}
  {{- $kindAllows := list "User" "Group" "ServiceAccount" }}
  {{- if $kind }}
    {{- include "base.field" (list "kind" $kind "base.string" $kindAllows) }}
  {{- end }}

  {{- /* name string */ -}}
  {{- $name := include "base.getValue" (list . "name") }}
  {{- if $name }}
    {{- include "base.field" (list "name" $name) }}
  {{- end }}

  {{- /* namespace string */ -}}
  {{- if eq $kind "ServiceAccount" }}
    {{- $namespace := include "base.getValue" (list . "namespace") }}
    {{- if empty $namespace }}
      {{- fail "old.Subject: kind=ServiceAccount namespace cannot be empty" }}
    {{- end }}
    {{- include "base.field" (list "namespace" $namespace "base.namespace") }}
  {{- end }}

  {{- /* apiGroup string */ -}}
  {{- $apiGroup := include "base.getValue" (list . "apiGroup") }}
  {{- if $apiGroup }}
    {{- include "base.field" (list "apiGroup" $apiGroup) }}
  {{- end }}
{{- end }}
