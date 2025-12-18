{{- define "definitions.PodAffinityTerm" -}}
  {{- /* labelSelector map */ -}}
  {{- $labelSelectorVal := include "base.getValue" (list . "labelSelector") | fromYaml }}
  {{- $labelSelector := include "definitions.LabelSelector" $labelSelectorVal | fromYaml }}
  {{- if $labelSelector }}
    {{- include "base.field" (list "labelSelector" $labelSelector "base.map") }}
  {{- end }}

  {{- /* matchLabelKeys array */ -}}
  {{- $matchLabelKeys := include "base.getValue" (list . "matchLabelKeys") | fromYamlArray }}
  {{- if $matchLabelKeys }}
    {{- include "base.field" (list "matchLabelKeys" (dict "s" $matchLabelKeys) "base.slice.cleanup") }}
  {{- end }}

  {{- /* namespaceSelector map */ -}}
  {{- $namespaceSelectorVal := include "base.getValue" (list . "namespaceSelector") | fromYaml }}
  {{- $namespaceSelector := include "definitions.LabelSelector" $namespaceSelectorVal | fromYaml }}
  {{- if $namespaceSelector }}
    {{- include "base.field" (list "namespaceSelector" $namespaceSelector "base.map") }}
  {{- end }}

  {{- /* namespaces array */ -}}
  {{- $namespaces := include "base.getValue" (list . "namespaces") | fromYamlArray }}
  {{- if $namespaces }}
    {{- include "base.field" (list "namespaces" (dict "s" $namespaces) "base.slice.cleanup") }}
  {{- end }}

  {{- /* topologyKey string */ -}}
  {{- $topologyKey := include "base.getValue" (list . "topologyKey") }}
  {{- if $topologyKey }}
    {{- include "base.field" (list "topologyKey" $topologyKey) }}
  {{- else }}
    {{- fail "definitions.PodAffinityTerm: topologyKey must be exists" }}
  {{- end }}
{{- end }}
