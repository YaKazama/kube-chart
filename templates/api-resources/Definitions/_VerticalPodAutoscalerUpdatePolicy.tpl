{{- /* vpa v1 */ -}}
{{- define "definitions.VerticalPodAutoscalerUpdatePolicy" -}}
  {{- /* evictionRequirements */ -}}
  {{- $evictionRequirementsVal := include "base.getValue" (list . "evictionRequirements") | fromYamlArray }}
  {{- $evictionRequirements := list }}
  {{- range $evictionRequirementsVal }}
    {{- $val := dict "items" (pick . "changeRequirement" "resources") }}
    {{- $evictionRequirements = append $evictionRequirements (include "definitions.EvictionRequirementsItems" $val | fromYaml) }}
  {{- end }}
  {{- $evictionRequirements = $evictionRequirements | mustUniq | mustCompact }}
  {{- if $evictionRequirements }}
    {{- include "base.field" (list "evictionRequirements" $evictionRequirements "base.slice") }}
  {{- end }}

  {{- /* minReplicas int */ -}}
  {{- $minReplicas := include "base.getValue" (list . "minReplicas") }}
  {{- if $minReplicas }}
    {{- include "base.field" (list "minReplicas" $minReplicas "base.int") }}
  {{- end }}

  {{- /* updateMode string */ -}}
  {{- $updateMode := include "base.getValue" (list . "updateMode") }}
  {{- $updateModeAllows := list "Off" "Initial" "Recreate" "InPlaceOrRecreate" "Auto" }}
  {{- if $updateMode }}
    {{- include "base.field" (list "updateMode" $updateMode "base.string" $updateModeAllows) }}
  {{- end }}
{{- end }}
