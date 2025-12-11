{{- define "definitions.LabelSelector" -}}
  {{- $_ := set . "_pkind" (get . "_kind") }}

  {{- /* matchExpressions */ -}}
  {{- $matchExpressionsVal := include "base.getValue" (list . "matchExpressions") | fromYamlArray }}
  {{- $matchExpressions := list }}
  {{- range $matchExpressionsVal }}
    {{- $matchExpressions = append $matchExpressions (include "definitions.LabelSelectorRequirement" . | fromYaml) }}
  {{- end }}
  {{- if $matchExpressions }}
    {{- include "base.field" (list "matchExpressions" $matchExpressions "base.slice") }}
  {{- end }}

  {{- /* matchLabels 与 labels 保持一致 此处不支持独立定义 */ -}}
  {{- $matchLabels := dict }}
  {{- if or (eq ._pkind "PodAffinityTerm") (eq ._pkind "TopologySpreadConstraint") (eq ._pkind "AggregationRule") (eq ._pkind "NetworkPolicySpec") }}
    {{- $matchLabels := include "base.getValue" (list . "matchLabels") | fromYaml }}
    {{- if $matchLabels }}
      {{- include "base.field" (list "matchLabels" $matchLabels "base.map") }}
    {{- end }}
  {{- else }}
    {{- $labels := include "base.getValue" (list . "labels") | fromYaml }}
    {{- $isHelmLabels := include "base.getValue" (list . "helmLabels") }}
    {{- if $isHelmLabels }}
      {{- $labels = mustMerge $labels (include "base.helmLabels" . | fromYaml) }}
    {{- end }}
    {{- if $labels }}
      {{- include "base.field" (list "matchLabels" $labels "base.map") }}
    {{- end }}
  {{- end }}

{{- end }}
