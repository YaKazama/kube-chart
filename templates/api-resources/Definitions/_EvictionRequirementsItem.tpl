{{- /* vpa v1 */ -}}
{{- define "definitions.EvictionRequirementsItem" -}}
  {{- /* changeRequirement string */ -}}
  {{- $changeRequirement := include "base.getValue" (list . "changeRequirement") }}
  {{- $changeRequirementAllows := list "TargetHigherThanRequests" "TargetLowerThanRequests" }}
  {{- if $changeRequirement }}
    {{- include "base.field" (list "changeRequirement" $changeRequirement "base.string" $changeRequirementAllows) }}
  {{- end }}

  {{- /* resources array */ -}}
  {{- $resourcesVal := include "base.getValue" (list . "resources") | fromYamlArray }}
  {{- $resources := list }}
  {{- range $resourcesVal }}
    {{- $val := dict "items" . }}
    {{- $resources = append $resources (include "definitions.EvictionRequirementsItemResource" $val | fromYaml) }}
  {{- end }}
  {{- $resources = $resources | mustUniq | mustCompact }}
  {{- if $resources }}
    {{- include "base.field" (list "resources" $resources "base.slice") }}
  {{- end }}
{{- end }}
