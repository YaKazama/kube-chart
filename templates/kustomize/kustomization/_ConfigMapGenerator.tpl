{{- define "kustomization.ConfigMapGenerator" -}}
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

  {{- /* behavior string */ -}}
  {{- $behavior := include "base.getValue" (list . "behavior") }}
  {{- $behaviorAllows := list "create" "replace" "merge" }}
  {{- if $behavior }}
    {{- include "base.field" (list "behavior" $behavior "base.string" $behaviorAllows) }}
  {{- end }}

  {{- /* files array */ -}}
  {{- $files := include "base.getValue" (list . "files") | fromYamlArray }}
  {{- if $files }}
    {{- include "base.field" (list "files" $files "base.slice") }}
  {{- end }}

  {{- /* envs array */ -}}
  {{- $envs := include "base.getValue" (list . "envs") | fromYamlArray }}
  {{- if $envs }}
    {{- include "base.field" (list "envs" $envs "base.slice") }}
  {{- end }}

  {{- /* literals array */ -}}
  {{- $literals := include "base.getValue" (list . "literals") | fromYamlArray }}
  {{- if $literals }}
    {{- include "base.field" (list "literals" $literals "base.slice") }}
  {{- end }}

  {{- /* options object/map */ -}}
  {{- $optionsVal := include "base.getValue" (list . "options") | fromYaml }}
  {{- if $optionsVal }}
    {{- $val := pick $optionsVal "labels" "annotations" "disableNameSuffixHash" "immutable" }}
    {{- $options := include "kustomization.GeneratorOption" $val | fromYaml }}
    {{- if $options }}
      {{- include "base.field" (list "options" $options "base.map") }}
    {{- end }}
  {{- end }}
{{- end }}
