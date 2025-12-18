{{- define "kustomize.Kustomization" -}}
  {{- $_ := set . "_kind" "Kustomization" }}

  {{- include "base.field" (list "apiVersion" "kustomize.config.k8s.io/v1beta1") }}
  {{- include "base.field" (list "kind" "Kustomization") }}

  {{- $const := include "base.env" "" | fromYaml }}

  {{- /* buildMetadata array */ -}}
  {{- $buildMetadata := include "base.getValue" (list . "buildMetadata") | fromYamlArray }}
  {{- $buildMetadataAllows := list "managedByLabel" "originAnnotations" "transformerAnnotations" }}
  {{- if $buildMetadata }}
    {{- include "base.field" (list "buildMetadata" (list $buildMetadata $buildMetadataAllows) "base.slice.allows") }}
  {{- end }}

  {{- /* commonAnnotations object/map */ -}}
  {{- $commonAnnotations := include "base.getValue" (list . "commonAnnotations") | fromYaml }}
  {{- if $commonAnnotations }}
    {{- include "base.field" (list "commonAnnotations" $commonAnnotations "base.map") }}
  {{- end }}

  {{- /* commonLabels object/map */ -}}
  {{- $commonLabels := include "base.getValue" (list . "commonLabels") | fromYaml }}
  {{- if $commonLabels }}
    {{- include "base.field" (list "commonLabels" $commonLabels "base.map") }}
  {{- end }}

  {{- /* components array */ -}}
  {{- $components := include "base.getValue" (list . "components") | fromYamlArray }}
  {{- if $components }}
    {{- include "base.field" (list "components" $components "base.slice") }}
  {{- end }}

  {{- /* configMapGenerator array */ -}}
  {{- $configMapGeneratorVal := include "base.getValue" (list . "configMapGenerator") | fromYamlArray }}
  {{- $configMapGenerator := list }}
  {{- range $configMapGeneratorVal }}
    {{- $isFiles := hasKey . "files" }}
    {{- $isLiterals := hasKey . "literals" }}
    {{- $isEnvFile := hasKey . "envs" }}

    {{- $val := dict }}
    {{- if $isFiles }}
      {{- $val = pick . "name" "namespace" "behavior" "files" "options" }}

    {{- else if $isLiterals }}
      {{- $val = pick . "name" "namespace" "behavior" "literals" "options" }}

    {{- else if $isEnvFile }}
      {{- $val = pick . "name" "namespace" "behavior" "envs" "options" }}
    {{- end }}

    {{- $configMapGenerator = append $configMapGenerator (include "kustomization.ConfigMapGenerator" $val | fromYaml) }}
  {{- end }}
  {{- $configMapGenerator = $configMapGenerator | mustUniq | mustCompact }}
  {{- if $configMapGenerator }}
    {{- include "base.field" (list "configMapGenerator" $configMapGenerator "base.slice") }}
  {{- end }}

  {{- /* crds array */ -}}
  {{- $crds := include "base.getValue" (list . "crds") | fromYamlArray }}
  {{- if $crds }}
    {{- include "base.field" (list "crds" $crds "base.slice") }}
  {{- end }}

  {{- /* generatorOptions map */ -}}
  {{- $generatorOptionsVal := include "base.getValue" (list . "generatorOptions") | fromYaml }}
  {{- if $generatorOptionsVal }}
    {{- $val := pick $generatorOptionsVal "labels" "annotations" "disableNameSuffixHash" "immutable" }}
    {{- $generatorOptions := include "kustomization.GeneratorOption" $val | fromYaml }}
    {{- if $generatorOptions }}
      {{- include "base.field" (list "generatorOptions" $generatorOptions "base.map") }}
    {{- end }}
  {{- end }}

  {{- /* helmCharts array */ -}}
  {{- $helmChartsVal := include "base.getValue" (list . "helmCharts") | fromYamlArray }}
  {{- $helmCharts := list }}
  {{- range $helmChartsVal }}
    {{- $helmCharts = append $helmCharts (include "kustomization.HelmChart" . | fromYaml) }}
  {{- end }}
  {{- $helmCharts = $helmCharts | mustUniq | mustCompact }}
  {{- if $helmCharts }}
    {{- include "base.field" (list "helmCharts" $helmCharts "base.slice") }}
  {{- end }}

  {{- /* helmGlobals map */ -}}
  {{- $helmGlobalsVal := include "base.getValue" (list . "helmGlobals") | fromYaml }}
  {{- if $helmGlobalsVal }}
    {{- $helmGlobals := include "kustomization.HelmGlobal" $helmGlobalsVal | fromYaml }}
    {{- if $helmGlobals }}
      {{- include "base.field" (list "helmGlobals" $helmGlobals "base.map") }}
    {{- end }}
  {{- end }}

  {{- /* images array */ -}}
  {{- $imagesVal := include "base.getValue" (list . "images") | fromYamlArray }}
  {{- $images := list }}
  {{- range $imagesVal }}
    {{- $images = append $images (include "kustomization.Image" . | fromYaml) }}
  {{- end }}
  {{- $images = $images | mustUniq | mustCompact }}
  {{- if $images }}
    {{- include "base.field" (list "images" $images "base.slice") }}
  {{- end }}

  {{- /* labels array */ -}}
  {{- $labelsVal := include "base.getValue" (list . "labels") | fromYamlArray }}
  {{- $labels := list }}
  {{- range $labelsVal }}
    {{- $labels = append $labels (include "kustomization.LabelSelector" . | fromYaml) }}
  {{- end }}
  {{- $labels = $labels | mustUniq | mustCompact }}
  {{- if $labels }}
    {{- include "base.field" (list "labels" $labels "base.slice") }}
  {{- end }}

  {{- /* namePrefix string */ -}}
  {{- $namePrefix := include "base.getValue" (list . "namePrefix") | lower }}
  {{- if $namePrefix }}
    {{- include "base.field" (list "namePrefix" (list $namePrefix $const.kustomize.prefix) "base.string.verify") }}
  {{- end }}

  {{- /* namespace string */ -}}
  {{- $namespace := include "base.getValue" (list . "namespace") }}
  {{- if $namespace }}
    {{- include "base.field" (list "namespace" $namespace "base.rfc1123") }}
  {{- end }}

  {{- /* nameSuffix string */ -}}
  {{- $nameSuffix := include "base.getValue" (list . "nameSuffix") | lower }}
  {{- if $nameSuffix }}
    {{- include "base.field" (list "nameSuffix" (list $nameSuffix $const.kustomize.suffix) "base.string.verify") }}
  {{- end }}

  {{- /* openapi map */ -}}
  {{- $openapiVal := include "base.getValue" (list . "openapi") | fromYaml }}
  {{- if $openapiVal }}
    {{- $openapi := include "kustomization.OpenAPI" $openapiVal | fromYaml }}
    {{- if $openapi }}
      {{- include "base.field" (list "openapi" $openapi "base.map") }}
    {{- end }}
  {{- end }}

  {{- /* patches array */ -}}
  {{- $patchesVal := include "base.getValue" (list . "patches") | fromYamlArray }}
  {{- $patches := list }}
  {{- range $patchesVal }}
    {{- $val := pick . "path" "patch" "target" "options" }}
    {{- $patches = append $patches (include "kustomization.Patches" $val | fromYaml) }}
  {{- end }}
  {{- $patches = $patches | mustUniq | mustCompact }}
  {{- if $patches }}
    {{- include "base.field" (list "patches" $patches "base.slice") }}
  {{- end }}

  {{- /* replacements array */ -}}
  {{- $replacementsVal := include "base.getValue" (list . "replacements") | fromYamlArray }}
  {{- $replacements := list }}
  {{- range $replacementsVal }}
    {{- $replacements = append $replacements (include "kustomization.Replacement" . | fromYaml) }}
  {{- end }}
  {{- $replacements = $replacements | mustUniq | mustCompact }}
  {{- if $replacements }}
    {{- include "base.field" (list "replacements" $replacements "base.slice") }}
  {{- end }}

  {{- /* replicas array */ -}}
  {{- $replicasVal := include "base.getValue" (list . "replicas") | fromYamlArray }}
  {{- $replicas := list }}
  {{- range $replicasVal }}
    {{- $replicas = append $replicas (include "kustomization.Replicas" . | fromYaml) }}
  {{- end }}
  {{- $replicas = $replicas | mustUniq | mustCompact }}
  {{- if $replicas }}
    {{- include "base.field" (list "replicas" $replicas "base.slice") }}
  {{- end }}

  {{- /* resources array */ -}}
  {{- $resources := include "base.getValue" (list . "resources") | fromYamlArray }}
  {{- if $resources }}
    {{- include "base.field" (list "resources" $resources "base.slice") }}
  {{- end }}

  {{- /* secretGenerator array */ -}}
  {{- $secretGeneratorVal := include "base.getValue" (list . "secretGenerator") | fromYamlArray }}
  {{- $secretGenerator := list }}
  {{- range $secretGeneratorVal }}
    {{- $secretGenerator = append $secretGenerator (include "kustomization.SecretGenerator" . | fromYaml) }}
  {{- end }}
  {{- $secretGenerator = $secretGenerator | mustUniq | mustCompact }}
  {{- if $secretGenerator }}
    {{- include "base.field" (list "secretGenerator" $secretGenerator "base.slice") }}
  {{- end }}

  {{- /* sortOptions map */ -}}
  {{- $sortOptionsVal := include "base.getValue" (list . "sortOptions") | fromYaml }}
  {{- $sortOptions := include "kustomization.SortOption" $sortOptionsVal | fromYaml }}
  {{- if $sortOptions }}
    {{- include "base.field" (list "sortOptions" $sortOptions "base.map") }}
  {{- end }}
{{- end }}
