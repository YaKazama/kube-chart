{{- define "kustomization.SecretGenerator" -}}
  {{- /* name string */ -}}
  {{- $name := include "base.getValue" (list . "name") }}
  {{- if $name }}
    {{- include "base.field" (list "name" $name "base.rfc1035") }}
  {{- end }}

  {{- /* namespace string */ -}}
  {{- $namespace := include "base.getValue" (list . "namespace") }}
  {{- if $namespace }}
    {{- include "base.field" (list "namespace" $namespace "base.rfc1123") }}
  {{- end }}

  {{- /* type string */ -}}
  {{- $type := include "base.getValue" (list . "type") }}
  {{- $typeAllows := list "Opaque" "kubernetes.io/service-account-token" "kubernetes.io/dockercfg" "kubernetes.io/dockerconfigjson" "kubernetes.io/basic-auth" "kubernetes.io/ssh-auth" "kubernetes.io/tls" "bootstrap.kubernetes.io/token" }}
  {{- if $type }}
    {{- include "base.field" (list "type" $type "base.string" $typeAllows) }}
  {{- end }}

  {{- /* files string array */ -}}
  {{- $files := include "base.getValue" (list . "files") | fromYamlArray }}
  {{- if $files }}
    {{- include "base.field" (list "files" $files "base.slice") }}
  {{- end }}

  {{- /* envs string array */ -}}
  {{- $envs := include "base.getValue" (list . "envs") | fromYamlArray }}
  {{- if $envs }}
    {{- include "base.field" (list "envs" $envs "base.slice") }}
  {{- end }}

  {{- /* options map */ -}}
  {{- $optionsVal := include "base.getValue" (list . "options") | fromYaml }}
  {{- if $optionsVal }}
    {{- $val := pick $optionsVal "labels" "annotations" "disableNameSuffixHash" "immutable" }}
    {{- $options := include "kustomization.GeneratorOption" $val | fromYaml }}
    {{- if $options }}
      {{- include "base.field" (list "options" $options "base.map") }}
    {{- end }}
  {{- end }}
{{- end }}
