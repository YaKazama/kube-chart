{{- define "definitions.IngressClassParametersReference" -}}
  {{- /* apiGroup string */ -}}
  {{- $apiGroup := include "base.getValue" (list . "apiGroup") }}
  {{- $_kind := include "base.getValue" (list . "kind") }}
  {{- if and (empty $apiGroup) (ne $_kind "core") }}
    {{- fail (printf "IngressClassParametersReference: apiGroup '%s' is required when kind is not core." $apiGroup) }}
  {{- end }}
  {{- if $apiGroup }}
    {{- include "base.field" (list "apiGroup" $apiGroup) }}
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
  {{- $_scope := include "base.getValue" (list . "scope") }}
  {{- if eq $_scope "Namespace" }}
    {{- $namespace := include "base.getValue" (list . "namespace") }}
    {{- if $namespace }}
      {{- include "base.field" (list "namespace" $namespace  "base.namespace") }}
    {{- end }}
  {{- end }}

  {{- /* scope string */ -}}
  {{- $scope := include "base.getValue" (list . "scope") }}
  {{- $scopeAllows := list "Cluster" "Namespace" }}
  {{- if $scope }}
    {{- include "base.field" (list "scope" $scope "base.string" $scopeAllows) }}
  {{- end }}
{{- end }}
