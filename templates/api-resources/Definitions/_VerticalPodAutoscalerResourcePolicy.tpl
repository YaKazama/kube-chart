{{- /* vpa v1 */ -}}
{{- define "definitions.VerticalPodAutoscalerResourcePolicy" -}}
  {{- /* containerPolicies array */ -}}
  {{- $containerPoliciesVal := include "base.getValue" (list . "containerPolicies") | fromYamlArray }}
  {{- $containerPolicies := list }}
  {{- range $containerPoliciesVal }}
    {{- $containerPolicies = append $containerPolicies (include "definitions.ContainerPoliciesMetricSource" . | fromYaml) }}
  {{- end }}
  {{- $containerPolicies = $containerPolicies | mustUniq | mustCompact }}
  {{- if $containerPolicies }}
    {{- include "base.field" (list "containerPolicies" $containerPolicies "base.slice") }}
  {{- end }}
{{- end }}
