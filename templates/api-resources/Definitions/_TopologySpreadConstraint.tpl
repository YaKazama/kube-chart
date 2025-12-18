{{- define "definitions.TopologySpreadConstraint" -}}
  {{- /* labelSelector map */ -}}
  {{- $labelSelectorVal := include "base.getValue" (list . "labelSelector") | fromYaml }}
  {{- $labelSelector := dict }}
  {{- if $labelSelectorVal }}
    {{- $val := pick $labelSelectorVal "matchExpressions" "matchLabels" }}
    {{- $labelSelector = include "definitions.LabelSelector" $val | fromYaml }}
    {{- if $labelSelector }}
      {{- include "base.field" (list "labelSelector" $labelSelector "base.map") }}
    {{- end }}
  {{- end }}

  {{- /* matchLabelKeys string array */ -}}
  {{- if $labelSelector }}
    {{- $matchLabelKeys := include "base.getValue" (list . "matchLabelKeys") | fromYamlArray }}
    {{- $matchLabelKeys = $matchLabelKeys | mustUniq | mustCompact }}
    {{- if $matchLabelKeys }}
      {{- include "base.field" (list "matchLabelKeys" $matchLabelKeys "base.slice") }}
    {{- end }}
  {{- end }}

  {{- /* maxSkew int */ -}}
  {{- $maxSkew := include "base.getValue" (list . "maxSkew") }}
  {{- if $maxSkew }}
    {{- include "base.field" (list "maxSkew" $maxSkew "base.int") }}
  {{- end }}

  {{- /* minDomains int */ -}}
  {{- $minDomains := include "base.getValue" (list . "minDomains") }}
  {{- if $minDomains }}
    {{- include "base.field" (list "minDomains" $minDomains "base.int") }}
  {{- end }}

  {{- /* nodeAffinityPolicy string */ -}}
  {{- $nodeAffinityPolicy := include "base.getValue" (list . "nodeAffinityPolicy") }}
  {{- $nodeAffinityPolicyAllows := list "Honor" "Ignore" }}
  {{- if $nodeAffinityPolicy }}
    {{- include "base.field" (list "nodeAffinityPolicy" $nodeAffinityPolicy "base.string" $nodeAffinityPolicyAllows) }}
  {{- end }}

  {{- /* nodeTaintsPolicy string */ -}}
  {{- $nodeTaintsPolicy := include "base.getValue" (list . "nodeTaintsPolicy") }}
  {{- $nodeTaintsPolicyAllows := list "Honor" "Ignore" }}
  {{- if $nodeTaintsPolicy }}
    {{- include "base.field" (list "nodeTaintsPolicy" $nodeTaintsPolicy "base.string" $nodeTaintsPolicyAllows) }}
  {{- end }}

  {{- /* topologyKey string */ -}}
  {{- $topologyKey := include "base.getValue" (list . "topologyKey") }}
  {{- if $topologyKey }}
    {{- include "base.field" (list "topologyKey" $topologyKey) }}
  {{- else }}
    {{- fail "topologyKey must be exists" }}
  {{- end }}

  {{- /* whenUnsatisfiable string */ -}}
  {{- $whenUnsatisfiable := include "base.getValue" (list . "whenUnsatisfiable") }}
  {{- $whenUnsatisfiableAllows := list "DoNotSchedule" "ScheduleAnyway" }}
  {{- if $whenUnsatisfiable }}
    {{- include "base.field" (list "whenUnsatisfiable" $whenUnsatisfiable "base.string" $whenUnsatisfiableAllows) }}
  {{- end }}
{{- end }}
