{{- define "definitions.HPAScalingRules" -}}
  {{- /* policies array */ -}}
  {{- $policiesVal := include "base.getValue" (list . "policies") | fromYamlArray }}
  {{- $policies := list }}
  {{- range $policiesVal }}
    {{- $policies = append $policies (include "definitions.HPAScalingPolicy" . | fromYaml) }}
  {{- end }}
  {{- $policies = $policies | mustUniq | mustCompact }}
  {{- if $policies }}
    {{- include "base.field" (list "policies" $policies "base.slice") }}
  {{- end }}

  {{- /* selectPolicy string */ -}}
  {{- $selectPolicy := include "base.getValue" (list . "selectPolicy") }}
  {{- if $selectPolicy }}
    {{- include "base.field" (list "selectPolicy" $selectPolicy) }}
  {{- end }}

  {{- /* stabilizationWindowSeconds int */ -}}
  {{- $stabilizationWindowSeconds := include "base.getValue" (list . "stabilizationWindowSeconds") }}
  {{- if $stabilizationWindowSeconds }}
    {{- include "base.field" (list "stabilizationWindowSeconds" (list (int $stabilizationWindowSeconds) 0 3600) "base.int.range") }}
  {{- end }}

  {{- /* tolerance Quantity */ -}}
  {{- $tolerance := include "base.getValue" (list . "tolerance") }}
  {{- if $tolerance }}
    {{- include "base.field" (list "tolerance" $tolerance "base.Quantity") }}
  {{- end }}
{{- end }}
