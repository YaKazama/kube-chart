{{- define "kustomization.HelmChart" -}}
  {{- /* additionalValuesFiles string array */ -}}
  {{- $additionalValuesFiles := include "base.getValue" (list . "additionalValuesFiles") | fromYamlArray }}
  {{- if $additionalValuesFiles }}
    {{- include "base.field" (list "additionalValuesFiles" $additionalValuesFiles "base.slice") }}
  {{- end }}

  {{- /* apiVersions string array */ -}}
  {{- $apiVersions := include "base.getValue" (list . "apiVersions") | fromYamlArray }}
  {{- if $apiVersions }}
    {{- include "base.field" (list "apiVersions" $apiVersions "base.slice") }}
  {{- end }}

  {{- /* chartHome string */ -}}
  {{- $chartHome := include "base.getValue" (list . "chartHome") }}
  {{- if $chartHome }}
    {{- include "base.field" (list "chartHome" $chartHome) }}
  {{- end }}

  {{- /* configHome string */ -}}
  {{- $configHome := include "base.getValue" (list . "configHome") }}
  {{- if $configHome }}
    {{- include "base.field" (list "configHome" $configHome) }}
  {{- end }}

  {{- /* includeCRDs bool */ -}}
  {{- $includeCRDs := include "base.getValue" (list . "includeCRDs") }}
  {{- if $includeCRDs }}
    {{- include "base.field" (list "includeCRDs" $includeCRDs "base.bool") }}
  {{- end }}

  {{- /* kubeVersion string */ -}}
  {{- $kubeVersion := include "base.getValue" (list . "kubeVersion") }}
  {{- if $kubeVersion }}
    {{- include "base.field" (list "kubeVersion" $kubeVersion) }}
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

  {{- /* nameTemplate string */ -}}
  {{- $nameTemplate := include "base.getValue" (list . "nameTemplate") }}
  {{- if $nameTemplate }}
    {{- include "base.field" (list "nameTemplate" $nameTemplate) }}
  {{- end }}

  {{- /* releaseName string */ -}}
  {{- $releaseName := include "base.getValue" (list . "releaseName") }}
  {{- if $releaseName }}
    {{- include "base.field" (list "releaseName" $releaseName) }}
  {{- end }}

  {{- /* repo string */ -}}
  {{- $repo := include "base.getValue" (list . "repo") }}
  {{- if $repo }}
    {{- include "base.field" (list "repo" $repo) }}
  {{- end }}

  {{- /* skipHooks bool */ -}}
  {{- $skipHooks := include "base.getValue" (list . "skipHooks") }}
  {{- if $skipHooks }}
    {{- include "base.field" (list "skipHooks" $skipHooks "base.bool") }}
  {{- end }}

  {{- /* valuesFile string */ -}}
  {{- $valuesFile := include "base.getValue" (list . "valuesFile") }}
  {{- if $valuesFile }}
    {{- include "base.field" (list "valuesFile" $valuesFile) }}
  {{- end }}

  {{- /* valuesInline map */ -}}
  {{- $valuesInline := include "base.getValue" (list . "valuesInline") | fromYaml }}
  {{- if $valuesInline }}
    {{- include "base.field" (list "valuesInline" $valuesInline "base.map") }}
  {{- end }}

  {{- /* valuesMerge string */ -}}
  {{- $valuesMerge := include "base.getValue" (list . "valuesMerge") }}
  {{- $valuesMergeAllows := list "merge" "override" "replace" }}
  {{- if $valuesMerge }}
    {{- include "base.field" (list "valuesMerge" $valuesMerge "base.string" $valuesMergeAllows) }}
  {{- end }}

  {{- /* version string */ -}}
  {{- $version := include "base.getValue" (list . "version") }}
  {{- if $version }}
    {{- include "base.field" (list "version" $version) }}
  {{- end }}

  {{- /* skipTests bool */ -}}
  {{- $skipTests := include "base.getValue" (list . "skipTests") }}
  {{- if $skipTests }}
    {{- include "base.field" (list "skipTests" $skipTests "base.bool") }}
  {{- end }}

{{- end }}
